class AddCommentModel < ActiveRecord::Migration
  def up
    create_table :comments do |t|
       t.integer  :user_id
       t.integer  :work_id
       t.text     :text
       t.timestamps
     end
     
     create_table :likes do |t|
        t.integer  :user_id
        t.integer  :work_id
        t.timestamps
      end
  end

  def down
    drop_table :comments
    drop_table :likes
  end
end
