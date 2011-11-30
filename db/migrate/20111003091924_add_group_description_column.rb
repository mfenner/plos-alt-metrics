class AddGroupDescriptionColumn < ActiveRecord::Migration
  def self.up
    rename_table :groups, :categories
    
    change_table(:categories) do |t|
      t.text :group_description
    end
  end

  def self.down
    rename_table :categories, :groups
    
    change_table(:categories) do |t|
      t.remove :group_description
    end
  end
end
