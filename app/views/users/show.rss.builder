xml.instruct! :xml, :version=>"1.0" 
xml.rss(:version=>"1.0") do
  xml.channel do
    xml.title("ScienceCard for #{@user.name}")
    xml.link("http://sciencecard.org/#{@user.username}")
    xml.dc :language, "en"
    @user.works.each do |work|
      xml.item do
        xml.rdf :about, "http://dx.doi.org/#{work.doi}"
        xml.title work.title
        xml.description formatted_citation(work, { :without_links => true })
        xml.link "http://doi.org/#{work.short_doi}"
        xml.dc :title, work.title
        work.contributors.each do |contributor|
          xml.dc :creator, contributor.name
        end 
        xml.dc :date, xml_date(work.published_on) unless work.published_on.blank?
        xml.prism :doi, work.doi
        xml.prism :url, "http://doi.org/#{work.short_doi}"
        if work.type == "JournalArticle"
          xml.prism :publicationName, work.journal.title unless work.journal.blank?
          xml.prism :issn, work.journal.issn unless work.journal.blank?
        end
        xml.prism :publicationDate, xml_date(work.published_on) unless work.published_on.blank?
        xml.prism :volume, work.volume unless work.volume.blank?
        xml.prism :number, work.issue unless work.issue.blank?
        xml.prism :startingPage, work.first_page unless work.first_page.blank?
        xml.prism :endingPage, work.last_page unless work.last_page.blank?
      end
    end
  end
end