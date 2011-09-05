class CreateAuthors < ActiveRecord::Migration
  def self.up
    create_table :authors do |t|
      t.string :name
      t.string :mas_id
      t.integer :staleness, :default => 14.days.to_i
      
      t.timestamps
    end
    
    create_table :articles_authors, :id => false do |t|
      t.column "article_id", :integer
      t.column "author_id", :integer
    end
  end

  def self.down
    drop_table :authors
    drop_table :articles_authors
  end
end
