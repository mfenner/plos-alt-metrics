class AddUrlColumn < ActiveRecord::Migration
  def up
    change_table(:works) do |t|
      t.string :url
    end
  end

  def down
    change_table(:works) do |t|
      t.remove :url
    end
  end
end
