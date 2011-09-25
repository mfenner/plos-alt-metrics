class Authentication < ActiveRecord::Base
  belongs_to :author
  
  validates_uniqueness_of :uid, :scope => :provider
end