# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20111120194344) do

  create_table "affiliations", :force => true do |t|
    t.string   "name"
    t.string   "mas"
    t.integer  "staleness",   :default => 1209600
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "homepageURL"
  end

  create_table "articles", :force => true do |t|
    t.string   "doi",                                                :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "retrieved_at",    :default => '1970-01-01 00:00:00', :null => false
    t.string   "pub_med"
    t.string   "pub_med_central"
    t.date     "published_on"
    t.text     "title"
    t.integer  "journal_id"
    t.text     "volume"
    t.text     "issue"
    t.text     "first_page"
    t.text     "last_page"
    t.integer  "year"
    t.integer  "mas"
    t.string   "mendeley"
    t.string   "mendeley_url"
    t.string   "scopus"
    t.string   "short_doi"
    t.integer  "book_id"
    t.string   "content_type"
  end

  add_index "articles", ["doi"], :name => "index_articles_on_doi", :unique => true

  create_table "articles_groups", :id => false, :force => true do |t|
    t.integer "article_id"
    t.integer "group_id"
  end

  create_table "authentications", :force => true do |t|
    t.integer  "author_id"
    t.string   "provider"
    t.string   "uid"
    t.string   "token"
    t.string   "secret"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "authors", :force => true do |t|
    t.string   "name"
    t.string   "mas"
    t.integer  "staleness",           :default => 1209600
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "sort_name"
    t.text     "image"
    t.text     "website"
    t.text     "native_name"
    t.string   "remember_token"
    t.datetime "remember_created_at"
    t.boolean  "admin",               :default => false
    t.string   "username"
    t.string   "location"
    t.text     "description"
    t.string   "mendeley"
    t.integer  "contributions_count"
    t.string   "twitter"
    t.integer  "sign_in_count",       :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "authorclaim"
    t.string   "scopus"
    t.string   "googlescholar"
  end

  create_table "books", :force => true do |t|
    t.string   "title"
    t.string   "isbn_print"
    t.string   "isbn_electronic"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "categories", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "article_description"
    t.text     "author_description"
    t.text     "group_description"
  end

  create_table "citations", :force => true do |t|
    t.integer  "retrieval_id"
    t.string   "uri",          :null => false
    t.text     "details"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "citations", ["retrieval_id", "uri"], :name => "index_citations_on_retrieval_id_and_uri", :unique => true
  add_index "citations", ["retrieval_id"], :name => "index_citations_on_retrieval_id"

  create_table "contributors", :force => true do |t|
    t.integer  "article_id"
    t.string   "surname"
    t.string   "given_name"
    t.string   "role"
    t.integer  "position"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "author_id"
    t.string   "service"
    t.string   "mas"
    t.string   "authorclaim"
    t.string   "crossref"
    t.string   "scopus"
  end

  create_table "friendships", :force => true do |t|
    t.integer  "author_id"
    t.string   "friend_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "groups", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "mendeley"
    t.text     "description"
    t.integer  "articles_count"
    t.integer  "members_count"
  end

  create_table "histories", :force => true do |t|
    t.integer  "retrieval_id",                   :null => false
    t.integer  "year",                           :null => false
    t.integer  "month",                          :null => false
    t.integer  "citations_count", :default => 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "histories", ["retrieval_id", "year", "month"], :name => "index_histories_on_retrieval_id_and_year_and_month", :unique => true

  create_table "journals", :force => true do |t|
    t.string   "title"
    t.string   "issn_print"
    t.string   "issn_electronic"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "members", :force => true do |t|
    t.integer  "author_id"
    t.integer  "group_id"
    t.boolean  "admin",      :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "positions", :force => true do |t|
    t.integer  "author_id"
    t.integer  "affiliation_id"
    t.boolean  "is_active"
    t.integer  "staleness",      :default => 1209600
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "retrievals", :force => true do |t|
    t.integer  "article_id",                                               :null => false
    t.integer  "source_id",                                                :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "retrieved_at",          :default => '1970-01-01 00:00:00', :null => false
    t.integer  "citations_count",       :default => 0
    t.integer  "other_citations_count", :default => 0
    t.string   "local_id"
    t.boolean  "running"
  end

  add_index "retrievals", ["article_id", "citations_count", "other_citations_count"], :name => "retrievals_article_id"
  add_index "retrievals", ["source_id", "article_id"], :name => "index_retrievals_on_source_id_and_article_id", :unique => true

  create_table "sources", :force => true do |t|
    t.string   "type"
    t.string   "url"
    t.string   "username"
    t.string   "password"
    t.integer  "staleness",     :default => 604800
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "active",        :default => true
    t.string   "name"
    t.boolean  "live_mode",     :default => false
    t.string   "salt"
    t.string   "searchURL"
    t.integer  "timeout",       :default => 30,     :null => false
    t.integer  "category_id"
    t.datetime "disable_until"
    t.integer  "disable_delay", :default => 10,     :null => false
    t.string   "partner_id"
    t.text     "misc"
    t.text     "prefix"
    t.boolean  "allow_reuse",   :default => true
  end

  add_index "sources", ["type"], :name => "index_sources_on_type", :unique => true

end
