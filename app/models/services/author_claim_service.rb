class AuthorClaimService < Service

  def self.get_works(user, options={})
    # Get works, return empty array if no authorclaim identifier, no response, or no works found
    return [] if user.authorclaim.blank?
    
    url = "ftp://ftp.authorclaim.org/#{user.authorclaim[1,1].to_s}/#{user.authorclaim[2,1].to_s}/#{user.authorclaim}.amf.xml"
    Rails.logger.info "AuthorClaim query: #{url}"
    
    SourceHelper.get_xml(url, options) do |document|
      results = []
      document.root.namespaces.default_prefix = 'amf'
      person = document.find_first("//amf:person")
      contributor = {}
      contributor["given_name"] = ""
      contributor["given_name"] << person.find_first("amf:givenname").content if person.find_first("amf:givenname")
      contributor["given_name"] << (contributor["given_name"].blank? ? "" : " ") + person.find_first("amf:additionalname").content if person.find_first("amf:additionalname")
      contributor["surname"] = person.find_first("amf:familyname").content if person.find_first("amf:familyname")
      document.find("//amf:isuserof/amf:text").each do |work|
        ref = work.attributes.get_attribute("ref").value
        # Only use work if reference has DOI
        next unless ref.match(/^info:lib\/crossref:/)
        result = {}
        result["DOI"] = CGI::unescape(ref[18..-1])
        result["Title"] = work.find_first("amf:title").content
        results << result
      end
      { :contributor => contributor, :works => results }
    end
  end

end