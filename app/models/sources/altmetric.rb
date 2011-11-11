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

class Altmetric < Source
  
  # Requires Mendeley Consumer Key
  def uses_partner_id; true; end

  def perform_query(article, options = {})
  
    url = "http://api.altmetric.com/unstable/doi/" + CGI.escape(article.doi)
    consumer_key= "&consumer_key=" + partner_id.to_s
    Rails.logger.info "Altmetric query: #{url + consumer_key}"
    results = SourceHelper.get_json(url + consumer_key, options)
    return [] if results.blank? 
    
    # Return 0 if no blog posts discussing this DOI found
    return 0 unless results["cited_by_feeds_count"].to_i > 0
    
    results = results["posts"]
    return [] if results.nil?

    Rails.logger.debug "Altmetric got #{results.inspect} for #{article.inspect}"
    if results
      citations = []
      results.each do |result|
        if result["type"] == "blog"
          citation = { :uri => result["url"] }
          citations << citation
        end
      end
    end
    citations
  end
  
end