class RenameAuthorModel < ActiveRecord::Migration
  def up
    drop_table :users
    rename_table :authors, :users
    rename_column :authentications, :author_id, :user_id
    rename_column :contributors, :author_id, :user_id
    rename_column :friendships, :author_id, :user_id
    rename_column :members, :author_id, :user_id
    rename_column :positions, :author_id, :user_id
  end

  def down
    rename_table :users, :authors
    rename_column :authentications, :user_id, :author_id
    rename_column :contributors, :user_id, :author_id
    rename_column :friendships, :user_id, :author_id
    rename_column :members, :user_id, :author_id
    rename_column :positions, :user_id, :author_id
    
    create_table "users", :force => true do |t|
      t.string   "name"
      t.string   "username"
      t.string   "location"
      t.text     "description"
      t.string   "image"
      t.string   "website"
      t.boolean  "admin"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string   "email",                                 :default => "", :null => false
      t.string   "encrypted_password",     :limit => 128, :default => "", :null => false
      t.string   "reset_password_token"
      t.datetime "reset_password_sent_at"
      t.datetime "remember_created_at"
      t.integer  "sign_in_count",                         :default => 0
      t.datetime "current_sign_in_at"
      t.datetime "last_sign_in_at"
      t.string   "current_sign_in_ip"
      t.string   "last_sign_in_ip"
    end
  end
end
