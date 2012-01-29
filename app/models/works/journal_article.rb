class JournalArticle < Work
  belongs_to :journal
  has_many :contributors, :foreign_key => :work_id
  
  validates :doi, :format => { :with => DOI::FORMAT }
  validates :doi, :uniqueness => true
  validates :journal_id, :presence => true
end