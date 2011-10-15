class AddShortDoiColumn < ActiveRecord::Migration
  def self.up
    change_table(:articles) do |t|
      t.string :short_doi
    end
  end

  def self.down
    change_table(:articles) do |t|
      t.remove :short_doi
    end
  end
end
