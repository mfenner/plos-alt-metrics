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

class Retrieval < ActiveRecord::Base
  @queue = :retrievals
  
  belongs_to :source
  belongs_to :work
  has_many :citations, :dependent => :destroy
  has_many :histories, :dependent => :destroy

  scope :most_cited_sample, :limit => 5,
    :order => "(citations_count + other_citations_count) desc"

  scope :active_sources,
    :conditions => "source_id in (select id from sources where active = 1)"

  scope :by_source, lambda { |source_id| {:conditions => ['source_id = ?', source_id] } }
  
  def total_citations_count
    citations_count + other_citations_count
  end

  def stale?
    new_record? or retrieved_at.nil? or (retrieved_at < source.staleness.ago)
  end

  def try_to_exclusively
    begin
      acquired = transaction do
        reload
        return false if running
        update_attribute :running, true
      end
      yield if acquired
    ensure
      update_attribute :running, false
    end
  end

  def to_included_json(options = {})
    result = {
      :source => source.name,
      :updated_at => retrieved_at.to_i,
      :count => total_citations_count
    }
    result[:citations] = citations.map(&:to_included_json) \
      if options[:citations] == "1" and not citations.empty?
    result[:histories] = histories.map(&:to_included_json) \
      if options[:history] == "1" and not histories.empty?
    public_url = source.public_url(self)
    result[:public_url] = public_url \
      if public_url
    result[:search_url] = source.searchURL if source.uses_search_url
    result
  end
  
  def to_csv(options = {})
    FasterCSV.generate do |csv|
      if total_citations_count > 0
        csv << [ "name", "uri"]
        csv << [ source.name, source.public_url(self) ]      
        csv << ""
        source.citations_to_csv(csv, self)
        csv << ""
      end
    end
  end

  def to_xml(options = {})
    options[:indent] ||= 2
    xml = options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])
    xml.instruct! unless options[:skip_instruct]
    attributes = {
      :source => source.name, 
      :updated_at => retrieved_at,
      :count => total_citations_count 
    }
    public_url = source.public_url(self)
    attributes[:public_url] = public_url if public_url
    attributes[:search_url] = source.searchURL if source.uses_search_url
        
    xml.tag!("source", attributes) do
      nested_options = options.merge!(:dasherize => false,
                                      :skip_instruct => true)
      if options[:citations] == "1" and not citations.empty?
        xml.tag!("citations") { citations.each {|c| c.to_xml(nested_options) } }
      end
      if options[:history] == "1" and not histories.empty?
        xml.tag!("histories") { histories.each {|h| h.to_xml(nested_options) } }
      end
    end
  end
  
  # Use Resque to asynchronously update retrieval
  def self.perform(retrieval_id, options={})
    retrieval = Retrieval.find(retrieval_id)
    Rails.logger.info "Asking #{retrieval.source.name} about #{retrieval.work.id}; last updated #{retrieval.retrieved_at}"
    
    success = true
    begin
      raw_citations = retrieval.source.query(retrieval.work, { :retrieval => retrieval, 
        :timeout => retrieval.source.timeout })

      if raw_citations == false
        Rails.logger.info "Skipping disabled source."
        success = false
      elsif raw_citations == nil
        Rails.logger.info "No citations found."
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
      Rails.logger.error "Unable to query"
      Rails.logger.error e.backtrace.join("\n")
      success = false
      raise
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
  
end