class AddPhotoUrlHomepageUrlToAuthors < ActiveRecord::Migration
  def self.up
    add_column :authors, :photoURL, :text
    add_column :authors, :homepageURL, :text
    add_column :affiliations, :homepageURL, :text
  end

  def self.down
    remove_column :authors, :photoURL
    remove_column :authors, :homepageURL
    remove_column :affiliations, :homepageURL
  end
end
