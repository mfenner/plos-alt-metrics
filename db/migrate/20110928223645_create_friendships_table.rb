class CreateFriendshipsTable < ActiveRecord::Migration
  def self.up
    create_table :friendships do |t|
       t.integer  :author_id
       t.string   :friend_id
       t.timestamps
     end
     
     change_table(:authors) do |t|
         t.string :twitter
       end
  end

  def self.down
    drop_table :friendships
    
    change_table(:authors) do |t|
        t.remove :twitter
      end
  end
end
