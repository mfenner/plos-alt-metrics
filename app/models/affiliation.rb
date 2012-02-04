class Affiliation < ActiveRecord::Base
  has_many :users, :through => :positions
  has_many :positions
  
  validates_presence_of :mas
  validates_uniqueness_of :mas
end
