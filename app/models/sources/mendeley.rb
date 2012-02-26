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

class Mendeley < Source
  
  # Requires Mendeley Consumer Key
  def uses_partner_id; true; end

  def perform_query(work, options = {})
  
    url = "http://api.mendeley.com/oapi/documents/details/" + CGI.escape(CGI.escape(work.doi)) + "?type=doi"
    consumer_key= "&consumer_key=" + partner_id.to_s
    Rails.logger.info "Mendeley query: #{url + consumer_key}"
    results = SourceHelper.get_json(url + consumer_key, options)
    return [] if results.blank? 
    
    stats = results["stats"]
    return [] if stats.nil?

    Rails.logger.debug "Mendeley got #{results.inspect} for #{work.inspect}"
    
    # Workaround as mendeley_url required to link to Mendeley page. Also fetch Mendeley internal id
    work.update_attributes(:mendeley => results["uuid"], :mendeley_url => results["mendeley_url"])

    stats["readers"].to_i
  end
  
  def public_url(retrieval)
    retrieval.work.mendeley_url.to_s && retrieval.work.mendeley_url.to_s
  end
  
end