xml.instruct! :xml, :version=>"1.0" 
xml.rss(:version=>"1.0") do
  xml.channel do
    xml.title("ScienceCard for #{@author.name}")
    xml.link("http://sciencecard.org/#{@author.username}")
    xml.dc :language, "en"
    @author.articles.each do |article|
      xml.item do
        xml.rdf :about, "http://dx.doi.org/#{article.doi}"
        xml.title article.title
        xml.link "http://doi.org/#{article.short_doi}"
        xml.dc :title, article.title
        article.contributors.each do |contributor|
          xml.dc :creator, contributor.name
        end 
        xml.dc :date, xml_date(article.published_on) unless article.published_on.blank?
        xml.prism :doi, article.doi
        xml.prism :url, "http://doi.org/#{article.short_doi}"
        xml.prism :publicationName, article.journal.title unless article.journal.blank?
        xml.prism :issn, article.journal.issn unless article.journal.blank?
        xml.prism :publicationDate, xml_date(article.published_on) unless article.published_on.blank?
        xml.prism :volume, article.volume unless article.volume.blank?
        xml.prism :number, article.issue unless article.issue.blank?
        xml.prism :startingPage, article.first_page unless article.first_page.blank?
        xml.prism :endingPage, article.last_page unless article.last_page.blank?
      end
    end
  end
end