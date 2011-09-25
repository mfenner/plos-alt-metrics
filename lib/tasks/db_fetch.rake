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

require 'yaml'
require 'erb'


namespace :db do
  FROM_ENV = "stage"

  desc "Download a copy of the remote #{FROM_ENV} database and replace the local #{Rails.env} database"
  task :fetch do
    pre_fetch

    puts "Retrieving #{FROM_ENV} data"
    db_config = YAML::load(ERB.new(IO.read("config/database.yml")).result)
    `ssh selfamusementpark.com -p3386 "mysqldump -u#{db_config[FROM_ENV]["username"]} -p#{db_config[FROM_ENV]["password"]} --opt --skip-extended-insert #{db_config[FROM_ENV]["database"]}" > tmp/#{FROM_ENV}.sql`

    post_fetch
  end

  desc "Replace the local #{Rails.env} database with the last #{FROM_ENV} database we fetched"
  task :refetch do
    pre_fetch
    post_fetch
  end

  def pre_fetch
    raise "Can't fetch into production" if Rails.env == "production"
    db_config = YAML::load(ERB.new(IO.read("config/database.yml")).result)
                
    puts "Recreating database"
    `sudo mysqladmin --force drop #{db_config[Rails.env]["database"]} || set status 0`
    `sudo mysqladmin create #{db_config[Rails.env]["database"]}`
    `echo \"grant all privileges on #{db_config[Rails.env]["database"]}.* to \'#{db_config[Rails.env]["username"]}\' identified by \'#{db_config[Rails.env]["password"]}\';\" | sudo mysql mysql`
    `sudo mysqladmin flush-privileges`
  end

  def post_fetch
    puts "Loading data into the #{Rails.env} database"
    db_config = YAML::load(ERB.new(IO.read("config/database.yml")).result)
    `mysql -u#{db_config[Rails.env]["username"]} -p#{db_config[Rails.env]["password"]} #{db_config[Rails.env]["database"]} <tmp/#{FROM_ENV}.sql`

    puts "Migrating"
    Rake::Task['db:migrate'].invoke
    if Rails.env == "development"
      puts "Cloning structure to test"
      Rake::Task['db:test:clone'].invoke
    end
  end
end
