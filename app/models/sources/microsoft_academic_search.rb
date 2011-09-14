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

class MicrosoftAcademicSearch < Source
  include SourceHelper
  
  def uses_partner_id; true; end

  def perform_query(article, options={})
    
    return nil if article.mas.blank?
    
    url = "http://academic.research.microsoft.com/json.svc/search?AppId="
    search_string = "&PublicationID="
    other_string = "&ResultObjects=Publication&ReferenceType=Citation&StartIdx=1&EndIdx=100&OrderBy=Year"
    
    Rails.logger.info "Microsoft Academic Search query: #{url}"
    
    results = get_json(url + partner_id.to_s + search_string + article.mas.to_s + other_string, options)["d"]["Publication"]
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
    citations
  end
  
  def public_url(retrieval)
    retrieval.article.mas.to_s && ("http://academic.research.microsoft.com/Detail?entitytype=1&searchtype=5&id=" \
      + retrieval.article.mas.to_s)
  end
  
end