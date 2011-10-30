class AddContributorColumns < ActiveRecord::Migration
  def self.up
    change_table :contributors do |t|
      t.integer :author_id
      t.string :service
      t.string :mas
      t.string :authorclaim
      t.string :crossref
      t.string :scopus
    end
   
    drop_table :contributions
  end

  def self.down
    change_table :contributors do |t|
      t.remove :author_id
      t.remove :service
    end
     
    create_table :contributions do |t|
      t.integer  "article_id"
      t.integer  "author_id"
      t.integer  "role"
      t.integer  "position"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.boolean  "mas",         :default => true
      t.boolean  "authorclaim", :default => false
     end
  end
end
