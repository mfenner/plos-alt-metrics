class AddAuthorclaimColumn < ActiveRecord::Migration
  def self.up
    change_table(:authors) do |t|
      t.string :authorclaim
    end
    change_table(:contributions) do |t|
      t.boolean :mas, :default => true
      t.boolean :authorclaim, :default => false
    end
  end

  def self.down
    change_table(:authors) do |t|
      t.remove :authorclaim
    end
    change_table(:contributions) do |t|
      t.remove :mas
      t.remove :authorclaim
    end
  end
end
