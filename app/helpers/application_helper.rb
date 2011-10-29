module ApplicationHelper
  
  def active_categories
    categories = Category.find :all, :conditions => ["sources.active=1"], :include => :sources, :order => :category_id
  end
  
  def mas_choices(author)
    Author.search_for_authors(author)
  end

  def xml_date(date)
    date.blank? ? nil : date.strftime("%Y-%m-%d")
  end
  
  def formatted_citation(article, options = {})
    formatted_citation = (article.contributors.blank? ? "" : article.contributors_to_display + ". ")
    if options[:without_links] 
      formatted_citation << article.journal.title + ". " unless article.journal.blank?
    else
      formatted_citation << link_to(article.journal.title, journal_path(article.journal.issn_print)) + ". " unless article.journal.blank?
    end
  	formatted_citation << article.book.title + ". " unless article.book.blank?
    formatted_citation << article.year.to_s + (article.volume ? ":#{article.volume}" : "") + (article.issue ? " (#{article.issue})" : "") + (article.first_page ? ";#{article.first_page}" : "") + (article.last_page ? "-#{article.last_page}": "")
  end
end