class RenameWorksGroupsTable < ActiveRecord::Migration
  def up
    rename_table :works_groups, :groups_works
  end

  def down
    rename_table :groups_works, :works_groups
  end
end
