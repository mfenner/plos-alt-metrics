class AddAuthorclaimColumn < ActiveRecord::Migration
  def self.up
    change_table(:authors) do |t|
      t.string :authorclaim
    end
  end

  def self.down
    change_table(:authors) do |t|
      t.remove :authorclaim
    end
  end
end
