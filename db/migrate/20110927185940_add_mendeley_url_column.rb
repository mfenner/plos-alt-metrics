class AddMendeleyUrlColumn < ActiveRecord::Migration
  def self.up
    change_table(:articles) do |t|
      t.string :mendeley_url
    end
  end

  def self.down
    change_table(:articles) do |t|
      t.remove :mendeley_url
    end
  end
end
