class AddGroupDescriptionColumn < ActiveRecord::Migration
  def self.up
    change_table(:categories) do |t|
      t.text :group_description
    end
  end

  def self.down
    change_table(:categories) do |t|
      t.remove :group_description
    end
  end
end
