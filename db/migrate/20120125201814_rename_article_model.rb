class RenameArticleModel < ActiveRecord::Migration
  def up
    rename_table :articles, :works
    rename_table :articles_groups, :works_groups
    rename_column :works_groups, :article_id, :work_id
    rename_column :contributors, :article_id, :work_id
    rename_column :retrievals, :article_id, :work_id
    rename_column :categories, :article_description, :work_description
    
    change_table(:categories) do |t|
      t.text :journal_description
    end
  end

  def down
    rename_table :works, :articles
    rename_table :works_gropus, :articles_groups
    rename_column :articles_groups, :work_id, :article_id
    rename_column :contributors, :work_id, :article_id
    rename_column :retrievals, :work_id, :article_id
    rename_column :categories, :work_description, :article_description
    
    change_table(:categories) do |t|
      t.remove :journal_description
    end
  end
end
