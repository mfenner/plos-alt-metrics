# Copyright (c) 2011 Martin Fenner
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

# Only return citation count unless specified in options with { :with_citations => true }
# Specify range of citations returned with { :startidx => 1, :endidx => 50 }

class MicrosoftAcademicSearch < Source
  
  def uses_partner_id; true; end

  def perform_query(article, options = {})
    
    return nil if article.mas.blank?
    
    options[:startidx] ||= 1
    options[:endidx] ||= 50
  
    url = "http://academic.research.microsoft.com/json.svc/search?AppId=" + partner_id.to_s
    publication_id = "&PublicationID=" + article.mas.to_s + "&ResultObjects=Publication"
    Rails.logger.info "Microsoft Academic Search query: #{url}"
    
    if options[:with_citations].nil?

      result_string = "&PublicationContent=MetaOnly&StartIdx=1&EndIdx=1"
      results = SourceHelper.get_json(url + publication_id + result_string, options)["d"]["Publication"]
      return nil if results.nil?

      results = results["Result"][0]
      return nil if results.nil?

      Rails.logger.debug "MAS got #{results.inspect} for #{article.inspect}"

      citations = results["CitationCount"].to_i
    else
      result_string = "&ReferenceType=Citation&StartIdx=" + options[:startidx].to_s + "&EndIdx=" + options[:endidx].to_s + "&OrderBy=Year"
      results = SourceHelper.get_json(url + publication_id + result_string, options)["d"]["Publication"]
      return nil if results.nil?
    
      results = results["Result"]
      return nil if results.nil?
    
      Rails.logger.debug "MAS got #{results.inspect} for #{article.inspect}"
      if results
        citations = []
        results.each do |result|
          mas = result['ID']
          if mas
            citation = {
              :uri => "http://academic.research.microsoft.com/Detail?entitytype=1&searchtype=5&id=" + mas.to_s
            }
            citations << citation
          end
        end
      end
    end
    citations
  end
  
  def public_url(retrieval)
    retrieval.article.mas.to_s && ("http://academic.research.microsoft.com/Detail?entitytype=1&searchtype=5&id=" \
      + retrieval.article.mas.to_s)
  end
  
end