class AddDeviseModules < ActiveRecord::Migration
  def self.up
    change_table :authors do |t|
      t.trackable
    end
  end

  def self.down
    change_table :authors do |t|
      t.remove :sign_in_count
      t.remove :current_sign_in_at
      t.remove :last_sign_in_at
      t.remove :current_sign_in_ip
      t.remove :last_sign_in_ip
    end
  end
end
