class AddNaturalNameToAuthors < ActiveRecord::Migration
  def self.up
    add_column :authors, :native_name, :text
    add_column :articles, :mas, :integer
    add_column :groups, :article_description, :text
    add_column :groups, :author_description, :text
  end

  def self.down
    remove_column :authors, :native_name
    remove_column :articles, :mas
    remove_column :groups, :article_description
    remove_column :groups, :author_description
  end
end
