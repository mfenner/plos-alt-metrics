class AddRatingCountColumn < ActiveRecord::Migration
  def self.up
    change_table(:authors) do |t|
      t.integer :ratings_count
    end
  end

  def self.down
    change_table(:authors) do |t|
      t.remove :ratings_count
    end
  end
end
