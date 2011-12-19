class Rating < ActiveRecord::Base
  
  belongs_to :post
  belongs_to :author, :counter_cache => true
  
  validates_uniqueness_of :post_id, :scope => :author_id
end
