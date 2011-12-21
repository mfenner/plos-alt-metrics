class AddSpamColumn < ActiveRecord::Migration
  def self.up
    change_table(:ratings) do |t|
      t.boolean :spam
    end
  end

  def self.down
    change_table(:ratings) do |t|
      t.remove :spam
    end
  end
end
