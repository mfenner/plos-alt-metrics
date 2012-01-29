class RenameContentTypeColumn < ActiveRecord::Migration
  def up
    rename_column :works, :content_type, :type
  end

  def down
    rename_column :works, :type, :content_type
  end
end
