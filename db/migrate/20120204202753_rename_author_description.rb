class RenameAuthorDescription < ActiveRecord::Migration
  def up
    rename_column :categories, :author_description, :user_description
  end

  def down
    rename_column :categories, :user_description, :author_description
  end
end
