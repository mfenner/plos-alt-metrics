class Authentication < ActiveRecord::Base
  belongs_to :user
  
  validates_uniqueness_of :uid, :scope => :provider
end