class Rating < ActiveRecord::Base
  
  belongs_to :post, :counter_cache => true
  belongs_to :author, :counter_cache => true
  
  validates_uniqueness_of :post_id, :scope => :author_id
  
  attr_accessible :post_id, :author_id, :rhetoric, :spam, :is_author, :method, :data, :conclusions
end
