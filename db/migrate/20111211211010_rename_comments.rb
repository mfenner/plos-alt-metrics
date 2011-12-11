class RenameComments < ActiveRecord::Migration
  def self.up
    rename_table :comments, :posts
  end

  def self.down
    rename_table :posts, :comments
  end
end
