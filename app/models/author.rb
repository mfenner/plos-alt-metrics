# Copyright Martin Fenner
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

class Author < ActiveRecord::Base
  extend SourceHelper
  
  has_and_belongs_to_many :articles, :order => "retrievals.citations_count desc, articles.published_on desc", :include => :retrievals
  has_many :positions
  
  # Check that no duplicate position is created
  has_many :affiliations, :through => :positions do
    def <<(*items)
      super( items - proxy_owner.affiliations )
    end
  end
  
  validates_numericality_of :mas_id
  validates_uniqueness_of :mas_id
  
  default_scope :order => 'authors.mas_id'
  
  named_scope :limit, lambda { |limit| (limit && limit > 0) ? {:limit => limit} : {} }
  
  def stale?
    new_record? or author.articles.empty?
  end

  def refreshed!
    self.updated_at = Time.zone.now
    self
  end
  
  def to_json(options={})
    result = { 
      :author => { 
        :mas_id => mas_id, 
        :name => name, 
        :articles_count => articles_count,
        :updated_at => updated_at
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
  
  def articles_count
    self.articles.count
  end
  
  def display_name
  	(self.native_name.blank? ? "" : self.native_name + " (") + (self.name.blank? ? self.mas_id : self.name) +  (self.native_name.blank? ? "" : ")")
	end
  
  def self.fetch_properties(author, options={})
    # Fetch author information, return nil if no response 
    url = "http://academic.research.microsoft.com/json.svc/search?AppId=#{APP_CONFIG['mas_app_id']}&ResultObjects=Author&AuthorID=#{author.mas_id}&StartIdx=1&EndIdx=1"
    Rails.logger.info "Microsoft Academic Search query: #{url}"
    result = get_json(url, options)["d"]["Author"]
    return nil if result.nil?
    
    properties = result["Result"][0]
  end
  
  def self.update_properties(author, properties, options={})
   # Update author information
    author_name = (properties["FirstName"].to_s.blank? ? "" : properties["FirstName"].to_s.capitalize + " ") + (properties["MiddleName"].to_s.blank? ? "" : properties["MiddleName"].to_s.capitalize + " ") + (properties["LastName"].to_s.blank? ? "" : properties["LastName"].to_s.capitalize)
    sort_name = properties["LastName"].to_s.capitalize
    author.update_attributes(:name => author_name, :sort_name => sort_name, :native_name => properties["NativeName"], :homepageURL => properties["HomepageURL"], :photoURL => properties["DisplayPhotoURL"])
    
    # Update affiliation information
    af_properties = properties["Affiliation"]
    unless af_properties.nil?
      affiliation = Affiliation.find_or_create_by_mas_id(:mas_id  => af_properties["ID"], :name => af_properties["Name"], :homepageURL => af_properties["HomepageURL"])
      author.affiliations << affiliation
    end
    author
  end
  
  def self.fetch_articles(author, options={})
    # Fetch articles, return nil if no response 
    url = "http://academic.research.microsoft.com/json.svc/search?AppId=#{APP_CONFIG['mas_app_id']}&ResultObjects=Publication&PublicationContent=AllInfo&AuthorID=#{author.mas_id}&StartIdx=1&EndIdx=50"
    Rails.logger.info "Microsoft Academic Search query: #{url}"
    
    result = get_json(url, options)["d"]["Publication"]
    return nil if result.nil?
    
    articles = result["Result"]
  end
  
  def citations_count(source, options={})
    citations = []
    self.articles.each do |article|
      citations << article.retrievals.sum(:citations_count, :conditions => ["retrievals.source_id = ?", source])
    end
    citations = citations.sum
  end
end
