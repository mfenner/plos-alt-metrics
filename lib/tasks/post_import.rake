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
    body, raw_original_id, url, content_type, author, raw_published_at, article_title, article_url, journal_title = post["body"], post["original_id"], post["url"], post["type"], post["authors"][0], post["pubdate"], post["papers_cited"][0]["title"], post["papers_cited"][0]["url"], post["papers_cited"][0]["journal"]
    published_at = Time.at(raw_published_at)
    original_id = raw_original_id[8..-1]
    if !body.nil? and content_type == "tweet"
      valid << [body, original_id, url, content_type, author, published_at, article_title, article_url, journal_title]
    else
      puts "Ignoring post: #{raw_original_id}, #{url}, #{content_type}"
      invalid << [body, original_id, url, content_type, author, published_at]
    end
  end
  puts "Read #{valid.size} valid entries; ignored #{invalid.size} invalid entries"
  if valid.size > 0
    valid.each do |body, original_id, url, content_type, author, published_at, article_title, article_url, journal_title|
      existing = Post.find_by_original_id(original_id)
      unless existing
        post = Post.create(:article_id => nil,
                           :body => body,
                           :original_id => original_id, 
                           :url => url,
                           :author => author,
                           :content_type => content_type,
                           :published_at => published_at,
                           :article_title => article_title,
                           :article_url => article_url,
                           :journal_title => journal_title)
        created << body
      else
        duplicate << body
      end
    end
  end
  puts "Saved #{created.size} new posts, ignored #{duplicate.size} other existing posts"
end