class AddScopusAuthorColumn < ActiveRecord::Migration
  def self.up
    change_table(:authors) do |t|
      t.string :scopus
    end
  end

  def self.down
    change_table(:authors) do |t|
      t.remove :scopus
    end
  end
end
