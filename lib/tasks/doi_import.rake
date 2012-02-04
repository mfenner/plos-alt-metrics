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

desc "Bulk-import works from standard input using URL"
task :doi_import => :environment do
  puts "Reading URLs from standard input..."
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
        #RetrievalWorker.async_retrieval(:article_id => article.id) 
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

desc "Bulk-import users from standard input using Twitter username"
task :user_import => :environment do
  puts "Reading Twitter usernames from standard input..."
  valid = []
  invalid = []
  duplicate = []
  created = []
  updated = []
  
  while (line = STDIN.gets)
    username, raw_name = line.strip.split(" ", 2)
    name = raw_name.strip if raw_name
    unless username.nil?
      valid << [username, name]
    else
      puts "Ignoring username: #{username}"
      invalid << [username, name]
    end
  end
  puts "Read #{valid.size} valid entries; ignored #{invalid.size} invalid entries"
  if valid.size > 0
    valid.each do |username, name|
      existing = user.find_by_username(username)
      unless existing
        user = user.create(:username => username, :name => name)
        created << username
      else
        duplicate << username
      end
    end
  end
  puts "Saved #{created.size} new users, updated #{updated.size} users, ignored #{duplicate.size} other existing users"
end

desc "Bulk-import groups from standard input using Mendeley group id"
task :group_import => :environment do
  puts "Reading Mendeley groups from standard input..."
  valid = []
  invalid = []
  duplicate = []
  created = []
  updated = []
  
  while (line = STDIN.gets)
    mendeley, raw_name = line.strip.split(" ", 2)
    name = raw_name.strip if raw_name
    unless mendeley.nil?
      valid << [mendeley, name]
    else
      puts "Ignoring Mendeley group id: #{mendeley}"
      invalid << [mendeley, name]
    end
  end
  puts "Read #{valid.size} valid entries; ignored #{invalid.size} invalid entries"
  if valid.size > 0
    valid.each do |mendeley, name|
      existing = Group.find_by_mendeley(mendeley)
      unless existing
        group = Group.create(:mendeley => mendeley, :name => name)
        created << mendeley
      else
        duplicate << mendeley
      end
    end
  end
  puts "Saved #{created.size} new groups, updated #{updated.size} groups, ignored #{duplicate.size} other existing groups"
end

desc "Bulk-import affiliations from standard input using mas id"
task :affiliation_import => :environment do
  puts "Reading mas ids from standard input..."
  valid = []
  invalid = []
  duplicate = []
  created = []
  updated = []
  
  while (line = STDIN.gets)
    mas, raw_name = line.strip.split(" ", 2)
    name = raw_name.strip if raw_name
    if mas.to_i.to_s == mas
      valid << [mas, name]
    else
      puts "Ignoring mas id: #{mas}"
      invalid << [mas, name]
    end
  end
  puts "Read #{valid.size} valid entries; ignored #{invalid.size} invalid entries"
  if valid.size > 0
    valid.each do |mas, name|
      existing = Affiliation.find_by_mas(mas)
      unless existing
        affiliation = Affiliation.create(:mas => mas, :name => name)
        created << mas_
      else
        duplicate << mas
      end
    end
  end
  puts "Saved #{created.size} new affiliations, updated #{updated.size} affiliations, ignored #{duplicate.size} other existing affiliations"
end