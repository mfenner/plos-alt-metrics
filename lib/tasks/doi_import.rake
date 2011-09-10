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

require 'doi'

desc "Bulk-import DOIs from standard input"
task :doi_import => :environment do
  puts "Reading DOIs from standard input..."
  valid = []
  invalid = []
  duplicate = []
  created = []
  updated = []
  sources = Source.all
  
  while (line = STDIN.gets)
    raw_doi, raw_published_on, raw_title = line.strip.split(" ", 3)
    doi = DOI::from_uri raw_doi.strip
    published_on = Date.parse(raw_published_on.strip) if raw_published_on
    title = raw_title.strip if raw_title
    if (doi =~ DOI::FORMAT) and !published_on.nil? and !title.nil?
      valid << [doi, published_on, title]
    else
      puts "Ignoring DOI: #{raw_doi}, #{raw_published_on}, #{raw_title}"
      invalid << [raw_doi, raw_published_on, raw_title]
    end
  end
  puts "Read #{valid.size} valid entries; ignored #{invalid.size} invalid entries"
  if valid.size > 0
    valid.each do |doi, published_on, title|
      existing = Article.find_by_doi(doi)
      unless existing
        article = Article.create(:doi => doi, :published_on => published_on, 
                       :title => title)
        RetrievalWorker.async_retrieval(:article_id => article.id) 
        created << doi
      else
        if existing.published_on != published_on or existing.title != title
          existing.published_on = published_on
          existing.title = title
          existing.save!
          updated << doi
        else
          duplicate << doi
        end
      end
    end
  end
  puts "Saved #{created.size} new articles, updated #{updated.size} articles, ignored #{duplicate.size} other existing articles"
end

desc "Bulk-import authors from standard input using mas_id"
task :author_import => :environment do
  puts "Reading mas_ids from standard input..."
  valid = []
  invalid = []
  duplicate = []
  created = []
  updated = []
  
  while (line = STDIN.gets)
    mas_id, raw_name = line.strip.split(" ", 2)
    name = raw_name.strip if raw_name
    if mas_id.to_i.to_s == mas_id
      valid << [mas_id, name]
    else
      puts "Ignoring mas_id: #{mas_id}"
      invalid << [mas_id, name]
    end
  end
  puts "Read #{valid.size} valid entries; ignored #{invalid.size} invalid entries"
  if valid.size > 0
    valid.each do |mas_id, name|
      existing = Author.find_by_mas_id(mas_id)
      unless existing
        author = Author.create(:mas_id => mas_id, :name => name)
        created << mas_id
      else
        duplicate << mas_id
      end
    end
  end
  puts "Saved #{created.size} new authors, updated #{updated.size} authors, ignored #{duplicate.size} other existing authors"
end

desc "Bulk-import affiliations from standard input using mas_id"
task :affiliation_import => :environment do
  puts "Reading mas_ids from standard input..."
  valid = []
  invalid = []
  duplicate = []
  created = []
  updated = []
  
  while (line = STDIN.gets)
    mas_id, raw_name = line.strip.split(" ", 2)
    name = raw_name.strip if raw_name
    if mas_id.to_i.to_s == mas_id
      valid << [mas_id, name]
    else
      puts "Ignoring mas_id: #{mas_id}"
      invalid << [mas_id, name]
    end
  end
  puts "Read #{valid.size} valid entries; ignored #{invalid.size} invalid entries"
  if valid.size > 0
    valid.each do |mas_id, name|
      existing = Affiliation.find_by_mas_id(mas_id)
      unless existing
        affiliation = Affiliation.create(:mas_id => mas_id, :name => name)
        created << mas_id
      else
        duplicate << mas_id
      end
    end
  end
  puts "Saved #{created.size} new affiliations, updated #{updated.size} affiliations, ignored #{duplicate.size} other existing affiliations"
end