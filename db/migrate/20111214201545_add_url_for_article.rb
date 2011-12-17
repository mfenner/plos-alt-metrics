class AddUrlForArticle < ActiveRecord::Migration
  def self.up
    change_table(:articles) do |t|
      t.string :url
    end
  end

  def self.down
    change_table(:articles) do |t|
      t.remove :url
    end
  end
end
