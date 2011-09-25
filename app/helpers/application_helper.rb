module ApplicationHelper
  
  def active_groups
    @groups = Group.find :all, :conditions => ["sources.active=1"], :include => :sources, :order => :group_id
  end

end