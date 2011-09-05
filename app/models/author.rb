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
  
  has_and_belongs_to_many :articles
  
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
    self.articles.count.to_s
  end
  
  def self.fetch_articles(author, options={})
    
    url = "http://academic.research.microsoft.com/json.svc/search?AppId=#{APP_CONFIG['mas_app_id']}&ResultObjects=Publication&PublicationContent=AllInfo&AuthorID=#{author.mas_id}&StartIdx=1&EndIdx=50"
    Rails.logger.info "Microsoft Academic Search query: #{url}"
    
    articles = get_json(url, options)["d"]["Publication"]["Result"]
  end
  
end
