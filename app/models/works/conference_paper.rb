class ConferencePaper < Work
  has_many :contributors, :foreign_key => :work_id
end