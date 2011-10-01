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

class Scopus < Source
  
  def uses_partner_id; true; end

  def perform_query(article, options = {})
  
    url = "http://api.elsevier.com/content/search/index:SCOPUS?query="
    publication_id = "doi(" + article.doi.to_s + ")"
    options[:extraheaders] = { "Accept"  => "application/json", "X-ELS-APIKey" => partner_id, "X-ELS-ResourceVersion" => "XOCS" }
    Rails.logger.info "Scopus query: #{url}"

    results = SourceHelper.get_json(url + publication_id, options)
    return [] if results.blank? 

    results = results["search-results"]["entry"]
    return [] if results.nil? 
    
    # Workaround if Scopus returns more than one result for a given DOI (which it shouldn't)
    results = results[0] if results.is_a? Array

    Rails.logger.debug "Scopus got #{results.inspect} for #{article.inspect}"
    
    # Workaround as Scopus ID required to link to Scopus page. Trim "SCOPUS_ID:"
    article.update_attributes(:scopus => results["dc:identifier"][10..-1])
    
    # Use prism:coverDate as a proxy for the publication date if no publication date yet
    article.update_attributes(:published_on => results["prism:coverDate"]) if article.published_on.blank?

    citations = results["citedby-count"].to_i
  end
  
  def public_url(retrieval)
    retrieval.article.scopus.to_s && ("http://www.scopus.com/inward/citedby.url?partnerID=HzOxMe3b&scp=" \
      + retrieval.article.scopus.to_s)
  end
  
end