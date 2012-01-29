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

class Book < ActiveRecord::Base
  has_many :book_contents
  has_many :conference_papers
  
  validates :isbn_print, :title, :presence => true
  
  def citations_count(source=nil, options={})
    citations = []
    book_contents.each do |book_content|
      unless source.nil?
        citations << book_content.retrievals.sum(:citations_count, :conditions => ["retrievals.source_id = ?", source])
        citations << book_content.retrievals.sum(:other_citations_count, :conditions => ["retrievals.source_id = ?", source])
      else
        citations << book_content.retrievals.sum(:citations_count)
        citations << book_content.retrievals.sum(:other_citations_count)
      end
    end
    citations = citations.sum
  end
  
  def get_cites_by_category(categoryname)
    citations = []
    categoryname = categoryname.downcase
    book_contents.each do |book_content|
      citations << book_content.retrievals.map do |ret|
        if ret.source.category.name.downcase == categoryname && (ret.citations_count + ret.other_citations_count) > 0
          #Cast this to an array to get around a ruby 'singularize' bug
          { :name => ret.source.name.downcase, :citations => ret.citations.to_a }
        end
      end.compact
    end
    citations = citations.sum
  end

end