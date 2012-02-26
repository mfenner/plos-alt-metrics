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

  def update(work)
    Rails.logger.info "Updating work #{work.inspect}..."
    if lazy and work.published_on and work.published_on >= Date.today
      Rails.logger.info "Skipping: work not published yet"
      return
    end
    
    # Update metadata via CrossRef
    # Work.update_via_crossref(work)

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
      # Check if source only works for specific DOI prefix
      if source.uses_prefix
        next unless work.doi.match(/^#{source.prefix}/)
      end

      retrieval = Retrieval.find_or_create_by_work_id_and_source_id(work.id, source.id)
      Rails.logger.debug "Retrieval is#{" (new)" if retrieval.new_record?} #{retrieval.inspect} (lazy=#{lazy.inspect}, stale?=#{retrieval.stale?.inspect})"

      retrieval.try_to_exclusively do
        if (not lazy) or retrieval.stale?
          Rails.logger.info "Refreshing source: #{source.inspect}"
          
          async_update_one(retrieval)
          # TODO: handle async retrieval
          sources_count = sources_count + 1
        else
          sources_count = sources_count + 1
          Rails.logger.info "Not refreshing source #{source.inspect}"
        end
      end
    end
    # If we are updating only one source
    #     do NOT update the work as refreshed
    # If all the sources do not update successfully
    #     do NOT update the work as refreshed
    if sources_count == sources.size and not only_source
      work.refreshed!.save!
      Rails.logger.info "Refreshed work #{work.doi}"
    else
      Rails.logger.info "Not refreshing work #{work.doi} (count: #{sources_count}, only src: #{only_source})"
    end
  end

  def async_update_one(retrieval)
    Resque.enqueue(Retrieval, retrieval.id)
  end

  def symbolize_keys_deeply(h)
    result = h.symbolize_keys
    result.each do |k,v|
      result[k] = symbolize_keys_deeply(v) if v.is_a? Hash
    end
    result
  end
  
  def update_works_by_user(user)
    Rails.logger.info "Updating user #{user.inspect}..."
    
    # Fetch works from user, return nil if no response
    results = User.fetch_works_from_mas(user)
    return nil if results.nil?
    
    results.each do |result|
      # Only add works with DOI and title
      unless result["DOI"].nil? or result["Title"].nil?
        result["DOI"] = DOI::clean(result["DOI"])
        work = Work.find_or_create_by_doi(:doi => result["DOI"], :url => "http://dx.doi.org/"+ result["DOI"], :mas => result["ID"], :title => result["Title"], :year => result["Year"])
        # Check that DOI is valid
        if work.valid?
          Work.update_via_crossref(work)
          unless user.works.include?(work)
            user.works << work 
          end
          # Create shortDOI if it doesn't exist yet
          if work.short_doi.blank?
            #work.update_attributes(:short_doi => DOI::shorten(work.doi)) 
          end
          Rails.logger.debug "Work is#{" (new)" if work.new_record?} #{work.inspect} (lazy=#{lazy.inspect}, stale?=#{work.stale?.inspect})"
        end
      end
    end  
    
    user.refreshed!.save!
    Rails.logger.info "Refreshed user #{user.mas}"
  end  
  
  def update_user(user)
    Rails.logger.info "Updating user #{user.inspect}..."
    
    # Fetch Microsoft Academic Search properties from user, return nil if no response
    properties = User.fetch_properties(user)
    return nil if properties.nil?
    
    user = User.update_properties(user, properties)
    
    # Update Twitter properties
    User.update_via_twitter(user)
    
    user.refreshed!.save!
    Rails.logger.info "Refreshed user #{user.username}"
  end

  def self.update_works(works, adjective=nil, timeout_period=50.minutes)
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
        Rails.logger.debug ["Updating", works.size.to_s,
              lazy ? "stale" : nil, adjective,
              works.size == 1 ? "work" : "works"].compact.join(" ")
        retriever = self.new(:lazy => lazy,
          :only_source => ENV["SOURCE"],
          :raise_on_error => ENV["RAISE_ON_ERROR"])

        works.each do |work|
          old_count = work.citations_count || 0
          retriever.update(work)
          new_count = work.citations_count || 0
          Rails.logger.debug "DOI: #{work.doi} count now #{new_count} (#{new_count - old_count})"
        end
      end
    rescue RetrieverTimeout => e
      Rails.logger.error "Timeout exceeded on work update" + e.backtrace.join("\n")
      raise e
    end
  end
  
  def self.update_users(users, adjective=nil, timeout_period=50.minutes, include_works=true)
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
        Rails.logger.debug ["Updating", users.size.to_s,
              lazy ? "stale" : nil, adjective,
              users.size == 1 ? "user" : "users"].compact.join(" ")
        retriever = self.new(:lazy => lazy,
          :raise_on_error => ENV["RAISE_ON_ERROR"])

        users.each do |user|
          retriever.update_user(user)
          if include_works
            old_count = user.works_count || 0
            retriever.update_works_by_user(user)
            new_count = user.works_count || 0
            Rails.logger.debug "MAS: #{user.mas} count now #{new_count} (#{new_count - old_count})"
          end
        end
      end
    rescue RetrieverTimeout => e
      Rails.logger.error "Timeout exceeded on user update" + e.backtrace.join("\n")
      raise e
    end
  end
  
end