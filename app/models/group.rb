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

class Group < ActiveRecord::Base
  has_many :members
  has_many :users, :through => :members
  has_and_belongs_to_many :works

  validates_presence_of :mendeley
  validates_uniqueness_of :mendeley
  
  def stale?
    new_record? or group.works.empty?
  end

  def refreshed!
    self.updated_at = Time.now
    self
  end
  
  def to_json(options={})
    result = { 
      :group => { 
        :mendeley => mendeley, 
        :name => name, 
        :works_count => works_count,
        :updated_at => updated_at
      }
    }
    
    @categories = Category.find :all, :conditions => ["sources.active=1"], :include => :sources, :order => :category_id
    result[:group][:citations] = []
    @categories.each do |category|
		  category.sources.active.each do |source|
	      result[:group][:citations] << [:source_id => source.id, :source_name => source.name, :count => self.citations_count(source)]
	    end
    end
    
    result[:group][:works] = []
    self.works.each do |work|
      result[:group][:works] << {:doi => work.doi, 
        :title => work.title, 
        :year => work.year,
        :pub_med => work.pub_med,
        :pub_med_central => work.pub_med_central,
        :mas => work.mas,
        :citations_count => work.citations_count,
        :published => (work.published_on.blank? ? nil : work.published_on.to_time),
        :updated_at => work.retrieved_at}
    end
    
    result.to_json(options)
  end
  
  def works_count
    self.works.count
  end
  
  def citations_count(source, options={})
    citations = []
    self.works.each do |work|
      citations << work.retrievals.sum(:citations_count, :conditions => ["retrievals.source_id = ?", source])
      citations << work.retrievals.sum(:other_citations_count, :conditions => ["retrievals.source_id = ?", source])
    end
    citations = citations.sum
  end
  
  def self.update_via_mendeley(mendeley, options={})
    # Fetch group basic information, return nil if no response 
    url = "http://api.mendeley.com/oapi/documents/groups/#{mendeley}?consumer_key=#{APP_CONFIG['mendeley_key']}"
    Rails.logger.info "Mendeley query: #{url}"
    
    result = SourceHelper.get_json(url, options)
    return nil if result.blank? or result["error"]
    
    # Update group information
    group = Group.find_or_create_by_mendeley(:mendeley => mendeley)
    group.update_attributes(:name => CGI.unescapeHTML(result["name"]))
    Rails.logger.debug "Group is#{" (new)" if group.new_record?} #{group.inspect}"
    group
  end
  
  def self.fetch_properties(group, options={})
    # Fetch group information, return nil if no response 
    url = "http://api.mendeley.com/oapi/documents/groups/#{group.mendeley}?consumer_key=#{APP_CONFIG['mendeley_key']}"
    Rails.logger.info "Mendeley query: #{url}"
    
    result = SourceHelper.get_json(url, options)
  end
  
  def self.update_properties(group, properties, options={})
    # Update group information
    group.update_attributes(:name => properties["name"], :mendeley => properties["id"], :works_count => properties["total_documents"])
    group
  end
  
  def self.fetch_works_from_mas(group, options={})
    # Fetch works, return nil if no response 
    
    options[:page] ||= 1
    options[:items] ||= 50
    
    url = "http://api.mendeley.com/oapi/documents/groups/#{group.mendeley}/docs/?details=true&page=#{options[:page]}&items=#{options[:items]}&consumer_key=#{APP_CONFIG['mendeley_key']}"
    Rails.logger.info "Mendeley query: #{url}"
    
    result = SourceHelper.get_json(url, options)
  end
end
