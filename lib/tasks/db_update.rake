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
require 'log4j_style_logger'

namespace :db do
  Rails.logger = ActiveSupport::BufferedLogger.new "#{Rails.root.to_s}/log/#{Rails.env}_db_update_rake.log"
  
  task :update => :"db:update:stale"
  namespace :update do
    desc "Update stale works"
    task :stale => :environment do
      puts "Start: #{Time.now.strftime("%Y-%m-%d %H:%M:%S")}"
      limit = (ENV["LIMIT"] || 0).to_i
      works = if ENV["DOI"]
        doi = ENV["DOI"]
        ENV["LAZY"] ||= "0"
        work = Work.find_by_doi(doi) or abort("Work not found: #{doi}")
        [work]
      elsif ENV["LAZY"] == "0"
        Work.limit(limit)
      else
        Work.stale_and_published.limit(limit)
      end
      
      puts "Found #{works.size} stale works."

      Retriever.update_works(works)
      
      puts "Done: #{Time.now.strftime("%Y-%m-%d %H:%M:%S")}"
    end

    desc "Update all works"
    task :all => :environment do
      ENV["LAZY"] = "0"
      limit = (ENV["LIMIT"] || 0).to_i
      works = Work.limit(limit)
      Retriever.update_works(works)
    end

    desc "Update cited works"
    task :cited => :environment do
      limit = (ENV["LIMIT"] || 0).to_i
      works = Work.cited.limit(limit)
      Retriever.update_works(works, "cited")
    end

    desc "Update one specified work"
    task :one => :environment do
      url = ENV["url"] or abort("URL not specified (eg, 'url=http://dx.doi.org/10.1/foo')")
      work = Work.find_by_url(url) or abort("Work not found: #{url}")
      ENV["LAZY"] ||= "0"
      Retriever.update_works([work])
    end
    
    desc "Update all users"
    task :users => :environment do
      ENV["LAZY"] = "0"
      limit = (ENV["LIMIT"] || 0).to_i
      users = User.limit(limit)
      Retriever.update_users(users)
    end
    
    desc "Update one specified user"
    task :one_user => :environment do
      username = ENV["username"] or abort("Username not specified (eg, 'username=mfenner')")
      user = User.find_by_username(username) or abort("User not found: #{twitter}")
      ENV["LAZY"] ||= "0"
      Retriever.update_users([user])
    end

    desc "Count stale works"
    task :count => :environment do
      work_count = Work.stale_and_published.count
      puts "#{work_count} stale works found"
    end

    desc "Reset works so individual sources' dates will be reconsidered"
    task :reset => :environment do
      Work.update_all("retrieved_at = '1970-01-01 00:00:00'")
      Retrieval.update_all("retrieved_at = '1970-01-01 00:00:00'")
    end

    desc "Reset all retrievals and citations"
    task :reset_all => :environment do
      Retrieval.delete_all
      Citation.delete_all
      History.delete_all
      Work.update_all("retrieved_at = '1970-01-01 00:00:00'")
    end

    desc "Reenable all disabled sources"
    task :reenable => :environment do
      # TODO: we should set disable_delay to Source.new.disable_delay, like we do in source.rb, instead of hard-coding the 10 here.
      Source.update_all("disable_until = NULL")
      Source.update_all("disable_delay = 10")
    end

    desc "Scan database for duplicate citations"
    task :dup_check => :environment do
      Retrieval.all.each do |retrieval|
        dups = []
        citations_by_uri = retrieval.citations.inject({}) do |h, citation|
          dups << citation if (h[citation.uri] ||= citation) != citation
          h
        end
        unless dups.empty?
          dups.each do |citation|
            puts "#{retrieval.work.doi} from #{retrieval.source.name} includes extra #{citation.uri}: #{citation.id}"
            if ENV['CLEANUP']
              puts "deleting citation #{citation.id}"
              retrieval.citations.delete(citation)
            end
          end
          if ENV['CLEANUP']
            new_count = retrieval.citations.size
            retrieval.histories.each do |h|
              if h.citations_count > new_count
                puts "updating history #{h.id}"
                h.citations_count = new_count
                h.save!
              end
            end
          end
        end
      end
    end
  end
end