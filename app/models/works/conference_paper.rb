class ConferencePaper < Work
  belongs_to :book
  has_many :contributors, :foreign_key => :work_id
end