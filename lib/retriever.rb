# $HeadURL$
# $Id$
#
# Copyright (c) 2009-2010 by Public Library of Science, a non-profit corporation
# http://www.plos.org/
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

class Retriever
  attr_accessor :lazy, :only_source, :raise_on_error

  def initialize(options={})
    #raise(ArgumentError, "Lazy must be specified as true or false") unless options.include?(:lazy)

    @lazy = options[:lazy]
    @only_source = options[:only_source]
    @raise_on_error = options[:raise_on_error]    
  end

  def update(article)
    Rails.logger.info "Updating article #{article.inspect}..."
    if lazy and article.published_on and article.published_on >= Time.zone.today
      Rails.logger.info "Skipping: article not published yet"
      return
    end

    # undoing revision 5150.  This way, we will always get the most current list of active sources.
    sources = Source.active
    if only_source
      sources = sources.select {|s| s.class.to_s.downcase == only_source.downcase }
      if sources.empty?
        Rails.logger.info "Only source '#{only_source}' not found or not active"
        return
      end
    elsif sources.empty?
      Rails.logger.info "No active sources to update from"
      return
    end

    sources_count = 0
    
    sources.each do |source|
      retrieval = Retrieval.find_or_create_by_article_id_and_source_id(article.id, source.id)
      Rails.logger.debug "Retrieval is#{" (new)" if retrieval.new_record?} #{retrieval.inspect} (lazy=#{lazy.inspect}, stale?=#{retrieval.stale?.inspect})"

      retrieval.try_to_exclusively do
        if (not lazy) or retrieval.stale?
          Rails.logger.info "Refreshing source: #{source.inspect}"
          #If one fails, make note, but then keep going.
          result = update_one(retrieval, source, article)
        
          if result
            sources_count = sources_count + 1
            Rails.logger.info "result=#{result}, sources_count incremented: #{sources_count}"
          else
            Rails.logger.error "result=#{result}, error refreshing article #{article.inspect}"
          end
        else
          sources_count = sources_count + 1
          Rails.logger.info "Not refreshing source #{source.inspect}"
        end
      end
    end
    # If we are updating only one source
    #     do NOT update the article as refreshed
    # If all the sources do not update successfully
    #     do NOT update the article as refreshed
    if sources_count == sources.size and not only_source
      article.refreshed!.save!
      Rails.logger.info "Refreshed article #{article.doi}"
    else
      Rails.logger.info "Not refreshing article #{article.doi} (count: #{sources_count}, only src: #{only_source})"
    end
  end

  def update_one(retrieval, source, article)
    Rails.logger.info "Asking #{source.name} about #{article.doi}; last updated #{retrieval.retrieved_at}"
    
    success = true
    begin
      raw_citations = source.query(article, { :retrieval => retrieval, 
        :timeout => source.timeout })

      if raw_citations == false
        Rails.logger.info "Skipping disabled source."
        success = false
      elsif raw_citations.is_a? Numeric  # Scopus returns a numeric count
        Rails.logger.info "Got a count of #{raw_citations.inspect} citations."
          
        retrieval.other_citations_count = raw_citations
        retrieval.retrieved_at = DateTime.now.utc
      else
        # Uniquify them - Sources sometimes return duplicates
        preunique_count = raw_citations.size
        raw_citations = raw_citations.inject({}) do |h, citation|
          h[citation[:uri]] = citation; h
        end
        Rails.logger.info "Got #{raw_citations.size} citation details."
        
        dupCount = preunique_count - raw_citations.size
        
        Rails.logger.debug "(after filtering out #{dupCount} duplicates!)"
            
        #Uniquify existing citations
        Rails.logger.debug "Existing citation count: #{retrieval.citations.size}"
        existing = retrieval.citations.inject({}) do |h, citation|
          h[citation[:uri]] = citation; h
        end
        Rails.logger.debug "After existing citations uniquified: #{existing.size}"

        raw_citations.each do |uri, raw_citation|
          #Loop through all citations, updating old, creating new.
          #Remove any old ones from the hash.
          dbCitation = existing.delete(uri)
          begin
            if dbCitation.nil?
              Rails.logger.info "Creating citation #{uri}"
              citation = retrieval.citations.create(:uri => uri,
                :details => symbolize_keys_deeply(raw_citation))
            else
              Rails.logger.info "Updating citation: #{dbCitation.id} "
              citation = retrieval.citations.update(dbCitation.id, {:details => symbolize_keys_deeply(raw_citation), :updated_at => DateTime.now })
            end
          rescue Timeout::Error, Timeout::ExitException
            raise
          rescue
            raise if raise_on_error
            Rails.logger.error "Unable to #{dbCitation.nil? ? 'create' : 'update'} #{raw_citation.inspect}"
            success = false
          end
        end
        
        #delete any existing database records that are still in the hash
        #(This will occur if a citation was created, but the later the source
        #giving us the citation stopped sending it)
        Rails.logger.debug "Deleting remaining existing citations: #{existing.size}"
        existing.values.map(&:destroy)
        retrieval.retrieved_at = DateTime.now.utc
      end
      #Note Issue: 21920, there is a strange problem where these citation counts are not always being set correctly.
      Rails.logger.debug "Citation count: #{retrieval.citations.size}"
      Retrieval.reset_counters retrieval.id, :citations
  
      retrieval.save!
    rescue Timeout::Error, Timeout::ExitException
      # do nothing
      success = false
    rescue RetrieverTimeout
      raise
    rescue Exception => e
      raise e if raise_on_error
      Rails.logger.error "Unable to query"
      Rails.logger.error e.backtrace.join("\n")
      success = false
    end

    if success
      retrieval.reload
      history = retrieval.histories.find_or_create_by_year_and_month(retrieval.retrieved_at.year, retrieval.retrieved_at.month)
      history.citations_count = retrieval.total_citations_count
      history.save!
      Rails.logger.info "Saved history[#{history.id}: #{history.year}, #{history.month}] = #{history.citations_count}"
    end
    success
  end

  def symbolize_keys_deeply(h)
    result = h.symbolize_keys
    result.each do |k,v|
      result[k] = symbolize_keys_deeply(v) if v.is_a? Hash
    end
    result
  end
  
  def update_author(author)
    Rails.logger.info "Updating author #{author.inspect}..."
    
    # Fetch articles from author, return nil if no response
    results = Author.fetch_articles(author)
    return nil if results.nil?
    
    results.each do |result|
      # Only add articles with DOI and title
      unless result["DOI"].nil? or result["Title"].nil?
        article = Article.find_or_create_by_doi(:doi  => result["DOI"], :title => result["Title"])
        # Check that DOI is valid
        if article.valid?
          author.articles << article unless author.articles.include?(article)
          # Add coauthors
          unless result["Author"].empty?
            result["Author"].each do |properties|
              coauthor = Author.find_or_create_by_mas_id(:mas_id  => properties["ID"])
              coauthor = Author.update_properties(coauthor, properties)
            end
          end
          Rails.logger.debug "Article is#{" (new)" if article.new_record?} #{article.inspect} (lazy=#{lazy.inspect}, stale?=#{article.stale?.inspect})"
        end
      end
    end  
    
    author.refreshed!.save!
    Rails.logger.info "Refreshed author #{author.mas_id}"
  end
  
  def update_affiliation(author)
    Rails.logger.info "Updating author #{author.inspect}..."
    
    # Fetch properties from author, return nil if no response
    properties = Author.fetch_properties(author)
    return nil if properties.nil?
    
    author = Author.update_properties(author, properties) 
    
    author.refreshed!.save!
    Rails.logger.info "Refreshed author #{author.mas_id}"
  end

  def self.update_articles(articles, adjective=nil, timeout_period=50.minutes)
    require 'timeout'
    begin

      # user can pass in the timeout value. expecting an integer value in minutes
      timeout_passed_in = ENV.fetch("TIMEOUT", 0).to_i
      if (timeout_passed_in > 0)
        timeout_period = timeout_passed_in.minutes
      end

      Rails.logger.info "Timeout value is #{timeout_period.to_i} seconds"
      
      Timeout::timeout timeout_period.to_i, RetrieverTimeout do
        lazy = ENV.fetch("LAZY", "1") == "1"
        Rails.logger.debug ["Updating", articles.size.to_s,
              lazy ? "stale" : nil, adjective,
              articles.size == 1 ? "article" : "articles"].compact.join(" ")
        retriever = self.new(:lazy => lazy,
          :only_source => ENV["SOURCE"],
          :raise_on_error => ENV["RAISE_ON_ERROR"])

        articles.each do |article|
          old_count = article.citations_count || 0
          retriever.update(article)
          new_count = article.citations_count || 0
          Rails.logger.debug "DOI: #{article.doi} count now #{new_count} (#{new_count - old_count})"
        end
      end
    rescue RetrieverTimeout => e
      Rails.logger.error "Timeout exceeded on article update" + e.backtrace.join("\n")
      raise e
    end
  end
  
  def self.update_authors(authors, adjective=nil, timeout_period=50.minutes, include_articles=false)
    require 'timeout'
    begin

      # user can pass in the timeout value. expecting an integer value in minutes
      timeout_passed_in = ENV.fetch("TIMEOUT", 0).to_i
      if (timeout_passed_in > 0)
        timeout_period = timeout_passed_in.minutes
      end

      Rails.logger.info "Timeout value is #{timeout_period.to_i} seconds"
      
      Timeout::timeout timeout_period.to_i, RetrieverTimeout do
        lazy = ENV.fetch("LAZY", "1") == "1"
        Rails.logger.debug ["Updating", authors.size.to_s,
              lazy ? "stale" : nil, adjective,
              authors.size == 1 ? "author" : "authors"].compact.join(" ")
        retriever = self.new(:lazy => lazy,
          :raise_on_error => ENV["RAISE_ON_ERROR"])

        authors.each do |author|
          retriever.update_affiliation(author)
          if include_articles
            old_count = author.articles_count || 0
            retriever.update_author(author)
            new_count = author.articles_count || 0
            Rails.logger.debug "MAS: #{author.mas_id} count now #{new_count} (#{new_count - old_count})"
          end
        end
      end
    rescue RetrieverTimeout => e
      Rails.logger.error "Timeout exceeded on author update" + e.backtrace.join("\n")
      raise e
    end
  end
  
end