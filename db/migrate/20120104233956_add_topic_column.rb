class AddTopicColumn < ActiveRecord::Migration
  def self.up
    change_table(:ratings) do |t|
      t.string :topic
    end
  end

  def self.down
    change_table(:ratings) do |t|
      t.string :topic
    end
  end
end
