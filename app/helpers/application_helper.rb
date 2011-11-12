module ApplicationHelper
  
  def active_categories
    categories = Category.find :all, :conditions => ["sources.active=1"], :include => :sources, :order => :category_id
  end
  
  def mas_choices(author)
    Author.search_for_mas_authors(author)
  end

  def xml_date(date)
    date.blank? ? nil : date.strftime("%Y-%m-%d")
  end
  
  def formatted_citation(article, options = {})
    formatted_citation = ""
    unless article.contributors.blank? 
      names = []
      article.contributors.each do |contributor|
        unless (contributor.author_id.blank? or options[:without_links])  
          names << link_to(contributor.brief_name, author_path(contributor.author.username))
        else
          names << contributor.brief_name
        end
      end
      if names.empty?
        formatted_citation << ""
      elsif names.size > 6
        names = names[0..5] 
        formatted_citation << names.join(", ") + ", et al. "
      else
        formatted_citation << names.join(", ") + ". "
      end
    end
    if options[:without_links] 
      formatted_citation << article.journal.title + ". " unless article.journal.blank?
    else
      formatted_citation << link_to(article.journal.title, journal_path(article.journal.issn_print)) + ". " unless article.journal.blank?
    end
  	formatted_citation << article.book.title + ". " unless article.book.blank?
    formatted_citation << article.year.to_s + (article.volume ? ":#{article.volume}" : "") + (article.issue ? " (#{article.issue})" : "") + (article.first_page ? ";#{article.first_page}" : "") + (article.last_page ? "-#{article.last_page}": "")
  end
end