class AddGoogleScholarColumn < ActiveRecord::Migration
  def self.up
    change_table(:authors) do |t|
      t.string :googlescholar
    end
  end

  def self.down
    change_table(:authors) do |t|
      t.remove :googlescholar
    end
  end
end
