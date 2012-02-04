class RenameAuthorModel < ActiveRecord::Migration
  def up
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
  end
end
