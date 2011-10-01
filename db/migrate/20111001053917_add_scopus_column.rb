class AddScopusColumn < ActiveRecord::Migration
  def self.up
    change_table(:articles) do |t|
      t.string :scopus
    end
  end

  def self.down
    change_table(:articles) do |t|
      t.remove :scopus
    end
  end
end
