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

desc "Bulk-import posts from standard input"
task :post_import => :environment do
  puts "Reading posts from standard input..."
  valid = []
  invalid = []
  duplicate = []
  created = []
  updated = []
  sources = Source.all
  
  file = File.open('import.json')
  contents = file.read
  posts = ActiveSupport::JSON.decode(contents)
  
  posts.each do |post|
    body, original_id, url, content_type, author = post["body"], post["original_id"], post["url"], post["type"], post["authors"][0]
    papers_cited = post["papers_cited"][0]
    #title, article_url = papers_cited["title"], papers_cited["url"]
    if !body.nil?
      valid << [body, original_id, url, content_type, author]
    else
      puts "Ignoring post: #{body}, #{original_id}, #{url}, #{content_type}"
      invalid << [body, original_id, url, content_type, author]
    end
  end
  puts "Read #{valid.size} valid entries; ignored #{invalid.size} invalid entries"
  if valid.size > 0
    valid.each do |body, original_id, url, content_type, author|
      existing = Post.find_by_original_id(original_id)
      unless existing
        #unless title.nil?
        #  article = Article.create(:title => title,
        #                           :url => article_url)
        #end
        post = Post.create(:article_id => nil,
                           :body => body,
                           :original_id => original_id, 
                           :url => url,
                           :author => author,
                           :content_type => content_type)
        created << body
      else
        duplicate << body
      end
    end
  end
  puts "Saved #{created.size} new posts, ignored #{duplicate.size} other existing posts"
end