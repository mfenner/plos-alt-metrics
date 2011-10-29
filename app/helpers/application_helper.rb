module ApplicationHelper
  
  def active_categories
    categories = Category.find :all, :conditions => ["sources.active=1"], :include => :sources, :order => :category_id
  end
  
  def mas_choices(author)
    Author.search_for_authors(author)
  end

  def xml_date(date)
    date.blank? ? nil : date.strftime("%Y-%m-%dT%H:%M:%S")
  end
end