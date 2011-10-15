class AddIssnColumn < ActiveRecord::Migration
  def self.up
    create_table :journals do |t|
      t.string   :title
      t.string   :issn_print
      t.string   :issn_electronic
      t.timestamps
    end
    
    create_table :books do |t|
      t.string   :title
      t.string   :isbn_print
      t.string   :isbn_electronic
      t.timestamps
    end
    
    change_table :articles do |t|
      t.integer :book_id
      t.string :content_type
      t.string :publication_type
      t.text :contributors
    end
  end

  def self.down
    drop_table :journals
    drop_table :books
    
    change_table :articles do |t|
      t.remove :book_id
      t.remove :content_type
      t.remove :publication_type
      t.remove :contributors
    end
  end
end
