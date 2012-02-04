class Position < ActiveRecord::Base
  belongs_to :user
  belongs_to :affiliation
  
  validates_uniqueness_of :user_id, :scope => "affiliation_id"
end
