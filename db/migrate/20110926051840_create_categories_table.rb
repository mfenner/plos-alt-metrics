class CreateCategoriesTable < ActiveRecord::Migration
  def self.up
    drop_table :users
    
    create_table "categories", :force => true do |t|
      t.string   "name"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.text     "article_description"
      t.text     "author_description"
    end
    
    change_table(:groups) do |t|
      t.remove :article_description
      t.remove :author_description
      t.string :mendeley
      t.text :description
      t.integer :articles_count
      t.integer :members_count
    end
    
    change_table(:articles) do |t|
      t.string :mendeley
    end
    
    change_table(:sources) do |t|
      t.rename :group_id, :category_id
    end
    
    create_table :members do |t|
      t.integer :author_id
      t.integer :group_id
      t.boolean  "admin", :default => false 
      t.timestamps
    end
    
    create_table :contributions do |t|
       t.integer :article_id
       t.integer :author_id
       t.integer :role
       t.integer :position 
       t.timestamps
     end
     
     drop_table :articles_authors
     
     change_table(:authors) do |t|
       t.integer :contributions_count
     end
    
    create_table :articles_groups, :id => false do |t|
      t.column "article_id", :integer
      t.column "group_id", :integer
    end
  end

  def self.down
    create_table :users, :force => true do |t|
      t.string   "login",                     :limit => 40
      t.string   "name",                      :limit => 100, :default => ""
      t.string   "email",                     :limit => 100
      t.string   "crypted_password",          :limit => 40
      t.string   "salt",                      :limit => 40
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "remember_token",            :limit => 40
      t.datetime "remember_token_expires_at"
    end
    add_index :users, ["login"], :name => "index_users_on_login", :unique => true
    drop_table :categories
    
    change_table(:groups) do |t|
      t.string :article_description
      t.string :author_description
      t.remove :mendeley
      t.remove :description
      t.remove :articles_count
      t.remove :members_count
    end
    
    change_table(:articles) do |t|
      t.remove :mendeley
    end
    
    change_table(:sources) do |t|
      t.rename :category_id, :group_id
    end
    
    drop_table :members
    drop_table :articles_groups
    drop_table :contributions
    
    change_table(:authors) do |t|
      t.remove :contributions_count
    end
    
    create_table :articles_authors, :id => false do |t|
      t.column "article_id", :integer
      t.column "author_id", :integer
    end
    
  end
end
