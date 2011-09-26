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
  has_many :authors, :through => :members
  has_and_belongs_to_many :articles

  validates_presence_of :mendeley
  validates_uniqueness_of :mendeley
  
  def stale?
    new_record? or group.articles.empty?
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
        :articles_count => articles_count,
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
    
    result[:group][:articles] = []
    self.articles.each do |article|
      result[:group][:articles] << {:doi => article.doi, 
        :title => article.title, 
        :year => article.year,
        :pub_med => article.pub_med,
        :pub_med_central => article.pub_med_central,
        :mas => article.mas,
        :citations_count => article.citations_count,
        :published => (article.published_on.blank? ? nil : article.published_on.to_time),
        :updated_at => article.retrieved_at}
    end
    
    result.to_json(options)
  end
  
  def articles_count
    self.articles.count
  end
  
  def self.fetch_properties(group, options={})
    # Fetch group information, return nil if no response 
    url = "http://api.mendeley.com/oapi/documents/groups/#{group.mendeley}?consumer_key=#{APP_CONFIG['mendeley_key']}"
    Rails.logger.info "Mendeley query: #{url}"
    
    result = SourceHelper.get_json(url, options)
  end
  
  def self.update_properties(group, properties, options={})
    # Update group information
    group.update_attributes(:name => properties["name"], :mendeley => properties["id"], :articles_count => properties["total_documents"])
    group
  end
  
  def self.fetch_articles(group, options={})
    # Fetch articles, return nil if no response 
    
    options[:page] ||= 1
    options[:items] ||= 50
    
    url = "http://api.mendeley.com/oapi/documents/groups/#{group.mendeley}/docs/?details=true&page=#{options[:page]}&items=#{options[:items]}&consumer_key=#{APP_CONFIG['mendeley_key']}"
    Rails.logger.info "Mendeley query: #{url}"
    
    result = SourceHelper.get_json(url, options)
  end
end
