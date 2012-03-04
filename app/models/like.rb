class Like < ActiveRecord::Base
  belongs_to :user
  belongs_to :work
  
  validates_uniqueness_of :work_id, :scope => :user_id
  
end