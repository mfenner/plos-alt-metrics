class Position < ActiveRecord::Base
  belongs_to :author
  belongs_to :affiliation
  
  validates_uniqueness_of :author_id, :scope => "affiliation_id"
end
