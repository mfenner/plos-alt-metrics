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

class Journal < ActiveRecord::Base
  has_many :journal_articles
  
  validates_uniqueness_of :issn_print
  validates_uniqueness_of :issn_electronic
  
  validates :isbn_print, :issn_electronic, :title, :presence => true
  
  def issn
    issn_print[0..3] + "-" + issn_print[4..7]
  end
  
  def journal_articles_count
    self.journal_articles.count
  end
  
  def citations_count(source=nil, options={})
    citations = []
    journal_articles.each do |journal_article|
      unless source.nil?
        citations << journal_article.retrievals.sum(:citations_count, :conditions => ["retrievals.source_id = ?", source])
        citations << journal_article.retrievals.sum(:other_citations_count, :conditions => ["retrievals.source_id = ?", source])
      else
        citations << journal_article.retrievals.sum(:citations_count)
        citations << journal_article.retrievals.sum(:other_citations_count)
      end
    end
    citations = citations.sum
  end
  
  def get_cites_by_category(categoryname)
    citations = []
    categoryname = categoryname.downcase
    journal_articles.each do |journal_article|
      citations << journal_article.retrievals.map do |ret|
        if ret.source.category.name.downcase == categoryname && (ret.citations_count + ret.other_citations_count) > 0
          #Cast this to an array to get around a ruby 'singularize' bug
          { :name => ret.source.name.downcase, :citations => ret.citations.to_a }
        end
      end.compact
    end
    citations = citations.sum
  end

end