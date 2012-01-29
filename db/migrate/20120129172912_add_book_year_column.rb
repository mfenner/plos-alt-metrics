class AddBookYearColumn < ActiveRecord::Migration
  def up
    change_table(:books) do |t|
      t.integer :year
    end
  end

  def down
    change_table(:books) do |t|
      t.remove :year
    end
  end
end
