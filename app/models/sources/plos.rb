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

class Plos < Source
  
  # Requires PLoS API Key, only fetches metrics for PLoS DOI prefix
  def uses_partner_id; true; end#
  def uses_prefix; true; end

  def perform_query(article, options = {})
    raise(ArgumentError, "PLoS configuration requires DOI prefix") \
      if prefix.blank?
  
    url = "http://alm.plos.org/articles/info:doi/" + CGI.escape(article.doi) + ".json?source=counter&citations=1"
    api_key= "&api_key=" + partner_id.to_s
    Rails.logger.info "PLoS query: #{url + api_key}"
    results = SourceHelper.get_json(url + api_key, options)
    
    return [] if results.blank? 

    results = results["article"]["source"][0]
    results = results["citations"][0]
    views = results["citation"]["views"]
    # Iterate over views array for combined count of views by month and type
    views_count = views.inject(0) { |sum, month| sum + month["html_views"].to_i + month["pdf_views"].to_i + month["xml_views"].to_i }

    Rails.logger.debug "PLoS got #{views.inspect} for #{article.inspect}"

    views_count
  end
  
  def public_url(retrieval)
    retrieval.article.doi.to_s && ("http://dx.doi.org/" \
      + retrieval.article.doi.to_s)
  end
  
end