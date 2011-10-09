class AddReuseColumn < ActiveRecord::Migration
  def self.up
    change_table(:sources) do |t|
      t.boolean :allow_reuse, :default => true
    end
  end

  def self.down
    change_table(:sources) do |t|
      t.remove :allow_reuse
    end
  end
end
