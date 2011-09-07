class Affiliation < ActiveRecord::Base
  has_many :authors, :through => :positions
  has_many :positions

end
