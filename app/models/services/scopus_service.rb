class ScopusService < Service

  def self.get_works(user, options={})
    # Get works, return empty array if no Scopus identifier, no response, or no works found
    return [] if user.scopus.blank?
    
    url = "http://api.elsevier.com/content/user/AUTHOR_ID:#{user.scopus}"
    options[:extraheaders] = { "Accept"  => "application/json", "X-ELS-APIKey" => APP_CONFIG['scopus_key'], "X-ELS-ResourceVersion" => "XOCS" }
    
    Rails.logger.info "Scopus query: #{url}"
    
    result = SourceHelper.get_json(url, options)
    return [] if result.nil?
    
    works = result["Result"]
  end

end