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

require "source_helper"
require 'oauth'

class Author < ActiveRecord::Base
  
  devise :rememberable, :omniauthable
  
  has_many :positions
  has_many :authentications
  has_many :contributions, :dependent => :destroy
  has_many :articles, :through => :contributions
  has_many :members
  has_many :groups, :through => :members
  has_many :friendships
  has_many :friends, :through => :friendships
  
  # Check that no duplicate position is created
  has_many :affiliations, :through => :positions do
    def <<(*items)
      super( items - proxy_owner.affiliations )
    end
  end
  
  attr_accessible :username, :name, :mas, :mendeley, :remember_me
  
  validates_numericality_of :mas, :allow_nil => true, :allow_blank => true
  validates_uniqueness_of :mas, :allow_nil => true, :allow_blank => true
  validates_presence_of :username
  validates_uniqueness_of :username
  
  default_scope :order => 'authors.sort_name'
  
  scope :limit, lambda { |limit| (limit && limit > 0) ? {:limit => limit} : {} }
    
  def self.find_for_twitter_oauth(omniauth)
    authentication = Authentication.find_by_provider_and_uid(omniauth['provider'], omniauth['uid'])
    if authentication && authentication.author
      authentication.author
    else
      author = Author.create!(:username => omniauth['user_info']['nickname'], 
                              :name => omniauth['user_info']['name'])
      author.authentications.create!(:provider => omniauth['provider'], 
                                     :uid => omniauth['uid'],
                                     :token => omniauth['credentials']['token'],
                                     :secret => omniauth['credentials']['secret'])
      author.save
      # Fetch aditional properties from Twitter
      #self.update_via_twitter(author)
      author
    end
  end
  
  def stale?
    new_record? or author.articles.empty?
  end

  def refreshed!
    self.updated_at = Time.now
    self
  end
  
  def to_json(options={})
    result = { 
      :author => { 
        :mas => mas, 
        :name => name, 
        :articles_count => articles_count,
        :updated_at => updated_at
      }
    }
    
    @categories = Category.find :all, :conditions => ["sources.active=1"], :include => :sources, :order => :category_id
    result[:author][:citations] = []
    @categories.each do |category|
		  category.sources.active.each do |source|
	      result[:author][:citations] << [:source_id => source.id, :source_name => source.name, :count => self.citations_count(source)]
	    end
    end
    
    result[:author][:affiliations] = []
    self.affiliations.each do |affiliation|
      result[:author][:affiliations] << {:mas => affiliation.mas, 
        :name => affiliation.name, 
        :homepageURL => affiliation.homepageURL,
        :updated_at => updated_at}
    end
    
    result[:author][:articles] = []
    self.articles.each do |article|
      result[:author][:articles] << {:doi => article.doi, 
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
  
  def display_name
  	(self.native_name.blank? ? "" : self.native_name + " (") + (self.name.blank? ? self.mas : self.name) +  (self.native_name.blank? ? "" : ")")
	end
  
  def self.fetch_properties(author, options={})
    # Fetch author information, return nil if no response 
    return nil if author.mas.blank?
    
    url = "http://academic.research.microsoft.com/json.svc/search?AppId=#{APP_CONFIG['mas_app_id']}&ResultObjects=Author&AuthorID=#{author.mas}&StartIdx=1&EndIdx=1"
    Rails.logger.info "Microsoft Academic Search query: #{url}"
    
    result = SourceHelper.get_json(url, options)["d"]["Author"]
    return nil if result.nil?
    
    properties = result["Result"][0]
  end
  
  def self.update_properties(author, properties, options={})
    # Update author information
    author.update_attributes(:sort_name => properties["LastName"].to_s.capitalize, :native_name => properties["NativeName"])
    
    # Update affiliation information
    af_properties = properties["Affiliation"]
    unless af_properties.nil?
      affiliation = Affiliation.find_or_create_by_mas(:mas  => af_properties["ID"], :name => af_properties["Name"], :homepageURL => af_properties["HomepageURL"])
      author.affiliations << affiliation
    end
    author
  end
  
  def self.search_for_authors(author, options={})
    # Fetch author information, return nil if no response 
    return nil if author.name.blank?
    url = "http://academic.research.microsoft.com/json.svc/search?AppId=#{APP_CONFIG['mas_app_id']}&FullTextQuery=#{CGI.escape(author.name)}&ResultObjects=Author&StartIdx=1&EndIdx=5"
    Rails.logger.info "Microsoft Academic Search query: #{url}"
    
    result = SourceHelper.get_json(url, options)["d"]["Author"]
    return nil if result.nil?
    
    properties = result["Result"]
    choices = []
    properties.each do |property|
      affiliation = property["Affiliation"].nil? ? "" : " (" + property["Affiliation"]["Name"] + ")"
      name_and_affiliation = (property["FirstName"].to_s.blank? ? "" : property["FirstName"].to_s.capitalize + " ") + (property["MiddleName"].to_s.blank? ? "" : property["MiddleName"].to_s.capitalize + " ") + (property["LastName"].to_s.blank? ? "" : property["LastName"].to_s.capitalize + affiliation + " - " + property["ID"].to_s)
      choices << [name_and_affiliation, property["ID"]]
    end
    choices
  end
  
  def self.update_via_twitter(author, options={})
    authentication = author.authentications.find(:first, :conditions => { :provider => 'twitter' })
    access_token = author.prepare_access_token(authentication)
    
     # Fetch information from Twitter, update description, location and image
    response = access_token.request(:get, "http://api.twitter.com/1/users/show.json?screen_name=#{author.username}")
    Rails.logger.info "Twitter query: #{url}"
    results = (response.body.length > 0) ? ActiveSupport::JSON.decode(response.body) : []
    
    # Find Twitter friends
    #response = access_token.request(:get, "https://api.twitter.com/1/friends/ids.json?cursor=-1&screen_name=#{@author.username}")
    #results = (response.body.length > 0) ? ActiveSupport::JSON.decode(response.body) : []
    #results["ids"].each do ||
      #@author.friends << friend unless author.friends.include?(friend)
    #end
    
    author.update_attributes(:description => results["description"], :location => results["location"], :image => results["profile_image_url"])
    author
  end
  
  def self.fetch_articles(author, options={})
    # Fetch articles, return empty array if no mas identifier, no response, or no articles found
    return [] if author.mas.blank?
    
    url = "http://academic.research.microsoft.com/json.svc/search?AppId=#{APP_CONFIG['mas_app_id']}&ResultObjects=Publication&PublicationContent=AllInfo&AuthorID=#{author.mas}&StartIdx=1&EndIdx=50"
    Rails.logger.info "Microsoft Academic Search query: #{url}"
    
    result = SourceHelper.get_json(url, options)["d"]["Publication"]
    return [] if result.nil?
    
    articles = result["Result"]
  end
  
  def citations_count(source, options={})
    citations = []
    self.articles.each do |article|
      citations << article.retrievals.sum(:citations_count, :conditions => ["retrievals.source_id = ?", source])
      citations << article.retrievals.sum(:other_citations_count, :conditions => ["retrievals.source_id = ?", source])
    end
    citations = citations.sum
  end
  
  # Exchange your oauth_token and oauth_token_secret for an AccessToken instance.
  def self.prepare_access_token(authentication)
    consumer = OAuth::Consumer.new('API key', 'API secret', { :site => "http://api.twitter.com" })
    token_hash = { :oauth_token => authentication.token, :oauth_token_secret => authentication.secret }
    access_token = OAuth::AccessToken.from_hash(consumer, token_hash)
  end
end