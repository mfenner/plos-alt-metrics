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

require 'bibtex'

class Article < ActiveRecord::Base
  
  has_many :retrievals, :dependent => :destroy, :order => "retrievals.source_id"
  has_many :sources, :through => :retrievals 
  has_many :citations, :through => :retrievals
  has_many :authors, :through => :contributors, :uniq => true
  has_many :contributors, :order => :position, :dependent => :destroy, :conditions => "contributors.service = 'mas'"
  has_and_belongs_to_many :groups
  belongs_to :journal
  belongs_to :book

  validates_format_of :doi, :with => DOI::FORMAT
  validates_uniqueness_of :doi

  after_create :create_retrievals

  scope :query, lambda { |query|
    { :conditions => [ "doi like ?", "%#{query}%" ] }
  }
  
  scope :cited, lambda { |cited|
    case cited
    when '1', 1
      { :include => :retrievals,
        :conditions => "retrievals.citations_count > 0 OR retrievals.other_citations_count > 0" }
    when '0', 0
      { :conditions => 'EXISTS (SELECT * from retrievals where article_id = `articles`.id GROUP BY article_id HAVING SUM(IFNULL(retrievals.citations_count,0)) + SUM(IFNULL(retrievals.other_citations_count,0)) = 0)' }
      #articles.id IN (SELECT articles.id FROM articles LEFT OUTER JOIN retrievals ON retrievals.article_id = articles.id GROUP BY articles.id HAVING IFNULL(SUM(retrievals.citations_count) + SUM(retrievals.other_citations_count), 0) = 0)' }
    else
      {}
    end
  }

  scope :limit, lambda { |limit| (limit && limit > 0) ? {:limit => limit} : {} }

  scope :order, lambda { |order|
    if order == 'published_on'
      { :order => 'published_on' }
    else
      {}
    end
  }

  scope :stale_and_published,
    :conditions => ["articles.id IN (
	SELECT DISTINCT article_id
	FROM retrievals 
	JOIN sources ON retrievals.source_id = sources.id 
	WHERE retrievals.article_id = articles.id 
	AND retrievals.retrieved_at < TIMESTAMPADD(SECOND, - sources.staleness, UTC_TIMESTAMP())
	AND sources.active = 1
	AND (
		sources.disable_until IS NULL 
		OR sources.disable_until < UTC_TIMESTAMP()))
	AND articles.published_on < ?", Date.today],
    :order => "retrievals.retrieved_at"

  default_scope :order => "IF(articles.published_on IS NULL, articles.year, articles.published_on) desc"

  def to_param
    DOI.to_uri(doi)
  end

  def doi=(new_doi)
    self[:doi] = DOI.from_uri(new_doi)
  end

  def stale?
    new_record? or retrievals.empty? or retrievals.active_sources.any?(&:stale?)
  end

  def refreshed!
    self.retrieved_at = Time.now
    self
  end
  
  #Get citation count by category and sources from the activerecord data
  def citations_by_category
    results = {}
    
    for ret in retrievals
      # Only get citations for active sources
      if ret.source.active
        if results[ret.source.category_id] == nil then
          results[ret.source.category_id] = {
            :name => ret.source.category && ret.source.category.name.downcase,
            :total => ret.citations_count + ret.other_citations_count,
            :sources => []
          }
          results[ret.source.category_id][:sources] << {
            :name => ret.source.name,
            :total => ret.citations_count + ret.other_citations_count,
            :public_url => ret.source.public_url(ret)
          }
        else
          results[ret.source.category_id][:total] = results[ret.source.category_id][:total] + ret.citations_count + ret.other_citations_count
          results[ret.source.category_id][:sources] << {
            :name => ret.source.name,
            :total => ret.citations_count + ret.other_citations_count,
            :public_url => ret.source.public_url(ret)
          }
        end
      end
    end
    
    categoriesCount = []
    
    results.each do | key, value |
      categoriesCount << value
    end
    
    categoriesCount
  end
  
  #Get citation count by source from the activerecord data
  def citations_by_source(source)
    
    return nil unless source.active
    ret = self.retrievals.by_source(source.id).first
    return if ret.nil?
    
    result = {
          :total => ret.citations_count + ret.other_citations_count,
          :public_url => ret.source.public_url(ret)
        }
    result
  end
  
  #Get cites for the given source from the activeRecord data
  def get_cites_by_category(categoryname)
    categoryname = categoryname.downcase
    retrievals.map do |ret|
      if ret.source.category.name.downcase == categoryname && (ret.citations_count + ret.other_citations_count) > 0
        #Cast this to an array to get around a ruby 'singularize' bug
        { :name => ret.source.name.downcase, :citations => ret.citations.to_a }
      end
    end.compact
  end
  
  def citations_count
    retrievals.inject(0) {|sum, r| sum + r.total_citations_count }
    # retrievals.sum(:citations_count) + retrievals.sum(:other_citations_count)
  end

  def cited_retrievals_count
    retrievals.select {|r| r.total_citations_count > 0 }.size
  end

  def to_xml(options = {})
    options[:indent] ||= 2
    sources = (options.delete(:source) || '').downcase.split(',')
    xml = options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])
    xml.instruct! unless options[:skip_instruct]
    xml.tag!("article", :doi => doi, :title => title, :citations_count => citations_count,:pub_med => pub_med,:pub_med_central => pub_med_central, :updated_at => retrieved_at, :published => (published_on.blank? ? nil : published_on.to_time)) do
      if options[:citations] or options[:history]
        retrieval_options = options.merge!(:dasherize => false, 
                                           :skip_instruct => true)
        retrievals.each do |r| 
          r.to_xml(retrieval_options) \
            if (sources.empty? or sources.include?(r.source['type'].downcase))
               #If the result set is emtpy, lets not return any information about the source at all
               #\
               #and (r.total_citations_count > 0)
        end
      end
    end
  end

  def explain
    msgs = ["[#{id}]: #{doi} #{retrieved_at}#{" stale" if stale?}"]
    retrievals.each {|r| msgs << "  [#{r.id}] #{r.source.name} #{r.retrieved_at}#{" stale" if r.stale?}"}
    msgs.join("\n")
  end

  def to_json(options={})
    result = { 
      :article => { 
        :doi => doi, 
        :shortdoi => "10/" + short_doi,
        :title => title, 
        :year => year,
        :pub_med => pub_med,
        :pub_med_central => pub_med_central,
        :mas => mas,
        :mendeley => mendeley,
        :citations_count => citations_count,
        :published => (published_on.blank? ? nil : published_on.to_time),
        :updated_at => retrieved_at
      }
    }
    sources = (options.delete(:source) || '').downcase.split(',')
    if options[:citations] or options[:history]
      result[:article][:source] = retrievals.map do |r|
        r.to_included_json(options) \
          if (sources.empty? or sources.include?(r.source.class.to_s.downcase))
             #If the result set is empty, lets not return any information about the source at all
             #\
             #and (r.total_citations_count > 0)
      end.compact
    end
    result.to_json(options)
  end
  
  def to_bib
    # Define BibTeX citation
    case content_type
    when "journal_article"
      bib_entry = BibTeX::Entry.new({
         :type => "article",
         :title => title,
         :author => contributors_with_names,
         :doi => doi,
         :url => "http://doi.org/" + short_doi,
         :journal => journal ? journal.title : ""})
      bib_entry.add(:year => year) unless year.blank?
      bib_entry.add(:volume => volume) unless volume.blank?
      bib_entry.add(:number => issue) unless issue.blank?
      bib_entry.add(:pages => pages) unless pages.blank?
    when "book_content"
      bib_entry = BibTeX::Entry.new({
         :type => "incollection",
         :title => title,
         :author => contributors_with_names,
         :doi => doi,
         :url => "http://doi.org/" + short_doi,
         :publisher => "",
         :booktitle => book ? book.title : ""})
      bib_entry.add(:year => year) unless year.blank?
      bib_entry.add(:volume => volume) unless volume.blank?
      bib_entry.add(:number => issue) unless issue.blank?
      bib_entry.add(:pages => pages) unless pages.blank?
    when "conference_paper"
      bib_entry = BibTeX::Entry.new({
         :type => "inproceedings",
         :title => title,
         :author => contributors_with_names,
         :doi => doi,
         :url => "http://doi.org/" + short_doi,
         :booktitle => book ? book.title : ""})
      bib_entry.add(:year => year) unless year.blank?
      bib_entry.add(:volume => volume) unless volume.blank?
      bib_entry.add(:number => issue) unless issue.blank?
      bib_entry.add(:pages => pages) unless pages.blank?
    end
  end
  
  def pages
    (first_page ? first_page : "") + ((first_page and last_page) ? "-" : "") + (last_page ? last_page : "")
  end
  
  def to_ris (options={})
    # Define RIS citation
    case content_type
    when "journal_article"
      ris = ["TY  - JOUR",
             "T1  - #{title}",
             "DO  - #{doi}",
             "UR  - http://doi.org/#{short_doi}"]
      contributors.each do |contributor|
        ris << "AU  - #{contributor.name}"
      end  
      ris << "JO  - #{journal.title}" unless journal.blank?
      ris << "PY  - #{year}" unless year.blank?
      ris << "VL  - #{volume}" unless volume.blank?
      ris << "IS  - #{issue}" unless issue.blank?
      ris << "SP  - #{pages}" unless pages.blank?
      ris << "ER  - "
      ris << ""
      ris.join("\r\n")
    when "book_content"
      ris = ["TY  - CHAP",
             "T1  - #{title}",
             "DO  - #{doi}",
             "UR  - http://doi.org/#{short_doi}"]
      contributors.each do |contributor|
        ris << "AU  - #{contributor.name}"
      end
      ris << "T2  - #{book.title}" unless book.blank?
      ris << "SN  - #{book.isbn_print}" unless book.blank?
      ris << "PY  - #{year}" unless year.blank?
      ris << "VL  - #{volume}" unless volume.blank?
      ris << "IS  - #{issue}" unless issue.blank?
      ris << "SP  - #{pages}" unless pages.blank?
      ris << "ER  - "
      ris << ""
      ris.join("\r\n")
    when "conference_paper"
      ris = ["TY  - CPAPER",
             "T1  - #{title}",
             "DO  - #{doi}",
             "UR  - http://doi.org/#{short_doi}"]
      contributors.each do |contributor|
        ris << "AU  - #{contributor.name}"
      end
      ris << "T2  - #{book.title}" unless book.blank?
      ris << "PY  - #{year}" unless year.blank?
      ris << "VL  - #{volume}" unless volume.blank?
      ris << "IS  - #{issue}" unless issue.blank?
      ris << "SP  - #{pages}" unless pages.blank?
      ris << "ER  - "
      ris << ""
      ris.join("\r\n")
    end
  end
  
  def contributors_with_names
    names = []
    contributors.each do |contributor| 
      names << contributor.name
    end
    names = names.empty? ? "" : names.join(" and ")
  end
  
  def self.fetch_from_mendeley(uuid, options={})
    # Fetch article information, return nil if no response 
    url = "http://api.mendeley.com/oapi/documents/details/#{uuid}?consumer_key=#{APP_CONFIG['mendeley_key']}"
    Rails.logger.info "Mendeley query: #{url}"
    
    result = SourceHelper.get_json(url, options)
  end
  
  def self.update_groups(article, options={})
    options[:groups] ||= []
    
    # Fetch group information from Mendeley if not provided, requires Mendeley uuid
    if options[:groups].empty?
      return nil if article.mendeley.blank?
      options[:groups] = self.fetch_from_mendeley(article.mendeley)["groups"] 
    end
    return nil if options[:groups].blank?
    
    options[:groups].each do |group_id|
      group = Group.find_by_mendeley(group_id["group_id"])
      
      # Create group if it doesn't exist and fetch name from Mendeley
      group = Group.update_via_mendeley(group_id["group_id"]) if group.nil?
      
      # If there was an error, e.g. group is private
      next if group.nil?
      
      article.groups << group unless article.groups.include?(group)
      Rails.logger.debug "Groups updated for article #{article.doi})"
    end
    
    article
  end
  
  def self.update_via_crossref(article, options={})
    # Update article information via CrossRef
    
    # First make sure you have correct DOI
    doi = DOI::clean(article.doi)
    
    # Delete article if cleaned DOI exists already
    if article.doi != doi
      other_article = Article.find_by_doi(doi)
      article.destroy unless other_article.blank?
      return nil
    end
    
    # Only use articles that have short DOI
    short_doi = article.short_doi.blank? ? DOI::shorten(doi) : article.short_doi
    if short_doi.blank?
      article.destroy
      return nil
    end
    
    # Fetch article information from CrossRef
    url = "http://www.crossref.org/openurl/?pid=#{APP_CONFIG['crossref_key']}&id=doi:"

    Rails.logger.info "CrossRef query: #{doi}"

    SourceHelper.get_xml(url + Addressable::URI.encode(doi) + "&noredirect=true", options) do |document|
      document.root.namespaces.default_prefix = "crossref_result"
      document.find("//crossref_result:body/crossref_result:query").each do |query_result|
        # Delete article if DOI not found at CrossRef
        if query_result.attributes.get_attribute("status").value != "resolved"
          article.destroy
        else
          result = {}
          %w[doi article_title year volume issue first_page last_page journal_title volume_title].each do |a|
            first = query_result.find_first("crossref_result:#{a}")
            if first
              content = first.content
              result[a.intern] = content
            end
          end
          issn_print = query_result.find_first("crossref_result:issn[@type='print']") ? query_result.find_first("crossref_result:issn[@type='print']").content : ""
          issn_electronic = query_result.find_first("crossref_result:issn[@type='electronic']") ? query_result.find_first("crossref_result:issn[@type='electronic']").content : ""
          
          isbn_print = query_result.find_first("crossref_result:isbn[@type='print']") ? query_result.find_first("crossref_result:isbn[@type='print']").content : ""
          isbn_electronic = query_result.find_first("crossref_result:isbn[@type='electronic']") ? query_result.find_first("crossref_result:isbn[@type='electronic']").content : ""
          
          result[:doi] = query_result.find_first("crossref_result:doi")
          result[:content_type] = result[:doi].attributes.get_attribute("type") ? result[:doi].attributes.get_attribute("type").value : ""
        
          #contributors_element = query_result.find_first("crossref_result:contributors")
          #extract_contributors(contributors_element, article) if contributors_element
        
          unless issn_print.blank? and issn_electronic.blank?
            # Remove dashes for consistency
            unless issn_electronic.blank?
              issn_electronic.gsub!(/[^0-9X]/, "")
            end
            unless issn_print.blank?
              issn_print.gsub!(/[^0-9X]/, "")
            end
            unless issn_print.blank?
              journal = Journal.find_or_create_by_issn_print(:issn_print => issn_print,
                                                             :title => result[:journal_title],
                                                             :issn_electronic => issn_electronic)
            else
              journal = Journal.find_or_create_by_issn_electronic(:issn_electronic => issn_electronic,
                                                                :title => result[:journal_title],
                                                                :issn_print => issn_electronic)
            end
            journal_id = journal.id
          else
            journal_id = nil
          end
          
          unless isbn_print.blank? and isbn_electronic.blank?
            unless isbn_print.blank?
              book = Book.find_or_create_by_isbn_print(:isbn_print => isbn_print,
                                                       :title => result[:volume_title],
                                                       :isbn_electronic => isbn_electronic)
            else
              book = Book.find_or_create_by_isbn_electronic(:isbn_electronic => isbn_electronic,
                                                          :title => result[:volume_title],
                                                          :isbn_print => isbn_electronic)
            end
            book_id = book.id
          else
            book_id = nil
          end
        
          article.update_attributes(:doi => doi,
                                  :short_doi => short_doi,
                                  :title => result[:article_title],
                                  :year => result[:year], 
                                  :volume => result[:volume],
                                  :issue => result[:issue],
                                  :first_page => result[:first_page],
                                  :last_page => result[:last_page],
                                  :content_type => result[:content_type],
                                  :journal_id => journal_id,
                                  :book_id => book_id)
        end
      end
    end  
  end
  
  protected
    def self.extract_contributors(contributors_element, article)
      # Remove contributors if they exist, then create them from scratch
      article.contributors.delete_all
      contributors = []
      contributors_element.find("crossref_result:contributor").each do |c|
        surname = c.find_first("crossref_result:surname")
        surname = surname.content if surname
        given_name = c.find_first("crossref_result:given_name")
        given_name = given_name.content if given_name
        given_name = given_name.split.map { |w| w.first.upcase }.join("") \
          if given_name
        position = nil
        position = 1 if c.attributes['sequence'] == 'first'
        role = c.attributes['contributor_role']
        article.contributors << Contributor.new(:surname => surname,
                                                :given_name => given_name,
                                                :position => position,
                                                :role => role,
                                                :service => "crossref")
      end
      article.contributors
    end

  private
    def create_retrievals
      # Create an empty retrieval record for each active source to avoid a
      # problem with joined tables breaking the UI on the front end
      Source.active.each do |source|
        Retrieval.find_or_create_by_article_id_and_source_id(id, source.id)
      end
    end
end
