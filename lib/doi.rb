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

module DOI
  # Format used for validation - we want to store DOIs without
  # the leading "info:doi/"
  FORMAT = %r(\d+\.[^/]+/[^/]+)

  def self.from_uri(doi)
    return nil if doi.nil?
    doi = doi.gsub("%2F", "/")
    if doi.starts_with? "http://dx.doi.org/"
      doi = doi[18..-1]
    end
    if doi.starts_with? "info:doi/"
      doi = doi[9..-1]
    end
    doi
  end

  def self.to_uri(doi, escaped=true)
    return nil if doi.nil?
    unless doi.starts_with? "info:doi"
      doi = "info:doi/" + from_uri(doi)
    end
    doi
  end

  def self.to_url(doi)
    return nil if doi.nil?
    unless doi.starts_with? "http://dx.doi.org/"
      doi = "http://dx.doi.org/" + from_uri(doi)
    end
    doi
  end
  
  def self.update_via_crossref(doi, options={})
    # Fetch article information from CrossRef
    url = "http://www.crossref.org/openurl/?pid=#{APP_CONFIG['crossref_key']}&id=doi:"

    Rails.logger.info "CrossRef query: #{doi}"

    SourceHelper.get_xml(url + CGI.escape(doi) + "&noredirect=true", options) do |document|
      document.root.namespaces.default_prefix = "crossref_result"
      document.find("//crossref_result:body/crossref_result:query").each do |query_result|
        # Delete article if DOI not found at CrossRef
        if query_result.attributes.get_attribute("status").value != "resolved"
          article = Article.find_by_doi(doi)
          article.destroy
        else
          result = {}
          %w[doi article_title year volume issue first_page last_page publication_type journal_title].each do |a|
            first = query_result.find_first("crossref_result:#{a}")
            if first
              content = first.content
              result[a.intern] = content
            end
          end
          issn_print = query_result.find_first("crossref_result:issn[@type='print']") ? query_result.find_first("crossref_result:issn[@type='print']").content : ""
          issn_electronic = query_result.find_first("crossref_result:issn[@type='electronic']") ? query_result.find_first("crossref_result:issn[@type='electronic']").content : ""
          
          isbn_print = query_result.find_first("crossref_result:isbn[@type='print']") ? query_result.find_first("crossref_result:isbn[@type='print']").content : ""
          isbn_electronic = query_result.find_first("crossref_result:isbn[@type='electronic']") ? query_result.find_first("crossref_result:isbn[@type='electronic']").content : ""
          
          result[:doi] = query_result.find_first("crossref_result:doi")
          result[:content_type] = result[:doi].attributes.get_attribute("type") ? result[:doi].attributes.get_attribute("type").value : ""
        
          contributors_element = query_result.find_first("crossref_result:contributors")
          result[:contributors] = contributors_element ? extract_contributors(contributors_element) : nil
        
          unless issn_print.blank? and issn_electronic.blank?
            # Remove dashes
            issn_print = issn_print.gsub(/[a-zA-Z0-9]/, "") unless issn_print.blank?
            issn_electronic = issn_electronic.gsub!(/[a-zA-Z0-9]/, "") unless issn_electronic.blank?
            
            journal = Journal.find(:first, :conditions => ["issn_print = ? OR issn_electronic = ?", issn_print, issn_electronic]) 
            if journal
              if (journal.title.blank? or journal.issn_print.blank? or journal.issn_electronic.blank?)
                journal.update_attributes(:title => result[:journal_title],
                                          :issn_print => issn_print,
                                          :issn_electronic => issn_electronic)
              end
            else
              journal = Journal.create(:title => result[:journal_title],
                                    :issn_print => issn_print,
                                    :issn_electronic => issn_electronic)
            end
            journal_id = journal.id
          else
            journal_id = nil
          end
          
          unless isbn_print.blank? and isbn_electronic.blank?
            
            book = Book.find(:first, :conditions => ["isbn_print = ? OR isbn_electronic = ?", isbn_print, isbn_electronic]) 
            if book
              if (book.title.blank? or book.isbn_print.blank? or book.isbn_electronic.blank?)
                book.update_attributes(:title => result[:volume_title],
                                          :isbn_print => isbn_print,
                                          :isbn_electronic => isbn_electronic)
              end
            else
              book = Book.create(:title => result[:volume_title],
                                    :isbn_print => isbn_print,
                                    :isbn_electronic => isbn_electronic)
            end
            book_id = book.id
          else
            book_id = nil
          end
        
          article = Article.find_or_create_by_doi(:doi => doi)
          if article.valid?
            article.update_attributes(:title => result[:article_title],
                                    :year => result[:year], 
                                    :volume => result[:volume],
                                    :issue => result[:issue],
                                    :first_page => result[:first_page],
                                    :last_page => result[:last_page],
                                    :content_type => result[:content_type],
                                    :publication_type => result[:publication_type],
                                    :journal_id => journal_id,
                                    :book_id => book_id,
                                    :contributors => result[:contributors])
          end
        end
      end
    end  
  end
  
  def self.clean(doi)
    return nil if doi.blank?
    # Remove component DOIs from PLoS articles
    if doi.match(/^10.1371/)
      doi.sub!(/\.s?[gt]00[1-9]$/, '')
    # Remove versions from Nature Preceedings
    elsif doi.match(/^10.1038\/npre/)
      doi.sub!(/\.\d$/, '')
    end
  end 
  
  def self.shorten(doi, options={})
    return nil if doi.blank?
    url = "http://shortdoi.org/" + CGI.escape(doi) + "?format=json"
    result = SourceHelper.get_json(url, options)
    return nil if result.blank?
    result["ShortDOI"]
  end
  
  protected
    def self.extract_contributors(contributors_element)
      contributors = []
      contributors_element.find("crossref_result:contributor").each do |c|
        surname = c.find_first("crossref_result:surname")
        surname = surname.content if surname
        given_name = c.find_first("crossref_result:given_name")
        given_name = given_name.content if given_name
        given_name = given_name.split.map { |w| w.first.upcase }.join("") \
          if given_name
        contributor = [surname, given_name].compact.join(", ")
        if c.attributes['first-author'] == 'true'
          contributors.unshift contributor
        else
          contributors << contributor
        end
      end
      contributors.join(" and ")
    end
end