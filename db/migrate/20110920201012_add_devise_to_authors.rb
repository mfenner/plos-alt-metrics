class AddDeviseToAuthors < ActiveRecord::Migration
  def self.up
    change_table(:authors) do |t|
      t.string :remember_token
      t.datetime :remember_created_at
      t.boolean :admin, :default => false
      t.string :username
      t.string :location
      t.text :description
      t.string :mendeley
      t.rename :photoURL, :image
      t.rename :homepageURL, :website
      t.rename :mas_id, :mas
    end
    
    change_table(:affiliations) do |t|
      t.rename :mas_id, :mas
    end

    create_table :authentications do |t|
      t.integer  :author_id
      t.string   :provider
      t.string   :uid
      t.string   :token
      t.string   :secret
      t.timestamps
    end
    
    #drop_table :users
    #add_index :authors, :email,                :unique => true
    #add_index :authors, :reset_password_token, :unique => true
    #add_index :authors, :twitter,   :unique => true
  end

  def self.down
    change_table(:authors) do |t|
      t.remove :remember_token
      t.remove :remember_created_at
      t.remove :admin
      t.remove :username
      t.remove :location
      t.remove :description
      t.remove :mendeley
      t.rename :image, :photoURL
      t.rename :website, :homepageURL
      t.rename :mas, :mas_id
    end
    change_table(:affiliations) do |t|
      t.rename :mas, :mas_id
    end
    drop_table :authentications
  end
end
