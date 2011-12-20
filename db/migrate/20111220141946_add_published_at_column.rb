class AddPublishedAtColumn < ActiveRecord::Migration
  def self.up
    change_table(:posts) do |t|
      t.datetime :published_at
      t.string :article_title
      t.string :article_url
      t.string :journal_title
    end
  end

  def self.down
    change_table(:posts) do |t|
      t.remove :published_at
      t.remove :article_title
      t.remove :article_url
      t.remove :journal_title
    end
  end
end
