class AddPrefixToSources < ActiveRecord::Migration
  def self.up
    add_column :sources, :prefix, :text
    add_column :articles, :journal_id, :integer
    add_column :articles, :volume, :text
    add_column :articles, :issue, :text
    add_column :articles, :first_page, :text
    add_column :articles, :last_page, :text
    add_column :articles, :year, :integer
  end

  def self.down
    remove_column :sources, :prefix
    remove_column :articles, :journal_id
    remove_column :articles, :volume
    remove_column :articles, :issue
    remove_column :articles, :first_page
    remove_column :articles, :last_page
    remove_column :articles, :year
  end
end
