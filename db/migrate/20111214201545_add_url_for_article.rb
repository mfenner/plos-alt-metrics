class AddUrlForArticle < ActiveRecord::Migration
  def self.up
    change_table(:articles) do |t|
      t.string :url
    end
    
    rename_column :ratings, :comment_id, :post_id
    rename_column :ratings, :author, :is_author
    rename_column :ratings, :discussion, :conclusions
    change_column :ratings, :rhetoric, :string
  end

  def self.down
    change_table(:articles) do |t|
      t.remove :url
    end
    
    rename_column :ratings, :post_id, :comment_id
    rename_column :ratings, :is_author, :author
    rename_column :ratings, :conclusions, :discussion
    change_column :ratings, :rhetoric, :integer
  end
end
