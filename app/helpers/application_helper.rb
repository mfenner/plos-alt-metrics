module ApplicationHelper
  
  def active_categories
    categories = Category.find :all, :conditions => ["sources.active=1"], :include => :sources, :order => :category_id
  end

end