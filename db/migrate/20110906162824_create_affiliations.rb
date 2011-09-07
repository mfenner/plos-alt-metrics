class CreateAffiliations < ActiveRecord::Migration
  def self.up
    create_table :affiliations do |t|
      t.string :name
      t.string :mas_id
      t.integer :staleness, :default => 14.days.to_i
      t.timestamps
    end
    
    create_table :positions do |t|
      t.integer :author_id
      t.integer :affiliation_id
      t.boolean :is_active
      t.integer :staleness, :default => 14.days.to_i
      t.timestamps
    end
    
    add_column :authors, :sort_name, :text
  end

  def self.down
    drop_table :affiliations
    drop_table :positions
    
    remove_column :authors, :sort_name
  end
end
