class AddAggregateCountsColumn < ActiveRecord::Migration
  def up
    add_column :categories, :add_sources, :boolean, :default => 1
  end

  def down
    remove_column :categories, :add_sources
  end
end
