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

class CrossRef < Source

  def uses_username; true; end

  def perform_query(work, options={})
    raise(ArgumentError, "Crossref configuration requires username") \
      if username.blank?

    url = "http://www.crossref.org/openurl/?pid=" + username + "&id=doi:"

    Rails.logger.info "CrossRef query: #{url}"

    SourceHelper.get_xml(url + Addressable::URI.encode(work.doi) + "&noredirect=true", options) do |document|
      citation_counts = []
      document.root.namespaces.default_prefix = "crossref_result"
      document.find("//crossref_result:body/crossref_result:query").each do |query_result|
        # return empty array if no DOI was found at CrossRef
        return [] if query_result.attributes.get_attribute("status").value != "resolved"
        
        citation_count = query_result.attributes.get_attribute("fl_count").value.to_i
        return [] if citation_count.nil?
        citation_counts << citation_count
      end
      citation_counts[0]
    end
  end
end