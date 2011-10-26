class CreateContributorsTable < ActiveRecord::Migration
  def self.up
    create_table :contributors do |t|
      t.integer :article_id
      t.string :surname
      t.string :given_name
      t.string :role
      t.integer :position
      t.timestamps
    end
    
    change_table :articles do |t|
      t.remove :publication_type
      t.remove :contributors
    end
  end

  def self.down
    drop_table :contributors
    
    change_table :articles do |t|
      t.string :publication_type
      t.text :contributors
    end
  end
end
