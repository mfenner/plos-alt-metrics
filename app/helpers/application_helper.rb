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
  
  def formatted_citation(work, options = {})
    formatted_citation = ""
    unless work.contributors.blank? 
      names = []
      work.contributors.each do |contributor|
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
    if work.type == "JournalArticle" and !work.journal.blank?
      if options[:without_links] 
        formatted_citation << "<em>" + work.journal.title + "</em>. "
      else
        formatted_citation << "<em>" + link_to(work.journal.title, journal_path(work.journal.issn_print)) + "</em>. "
      end
    elsif (work.type == "BookContent" or work.type == "ConferencePaper") and !work.book.blank?
      if options[:without_links]
  	    formatted_citation << "In: " + work.book.title + ". "
  	  else
  	    formatted_citation << "In: " + link_to(work.book.title, book_path(work.book.isbn_print)) + ". "
  	  end
  	end
    formatted_citation << work.year.to_s + (work.volume ? ":#{work.volume}" : "") + (work.issue ? " (#{work.issue})" : "") + (work.first_page ? ";#{work.first_page}" : "") + ((work.last_page and work.last_page > work.first_page) ? "-#{work.last_page}": "")
  end
end