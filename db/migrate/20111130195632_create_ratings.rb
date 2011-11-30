class CreateRatings < ActiveRecord::Migration
  def self.up
    create_table :comments do |t|
      t.integer :article_id
      t.text :body
      t.string :original_id
      t.string :content_type
      t.string :author
      t.string :url

      t.timestamps
    end

    create_table :ratings do |t|
      t.integer :author_id
      t.integer :comment_id
      t.integer :rhetoric
      t.boolean :method
      t.boolean :data
      t.boolean :discussion
      t.boolean :author

      t.timestamps
    end
  end

  def self.down
    drop_table :comments
    drop_table :ratings
  end
end
