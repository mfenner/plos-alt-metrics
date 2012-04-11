class MicrosoftAcademicSearchService < Service
  
  def self.get_works(user, options={})
    # Get works, return empty array if no mas identifier, no response, or no works found
    return [] if user.mas.blank?
    
    url = "http://academic.research.microsoft.com/json.svc/search?AppId=#{APP_CONFIG['mas_app_id']}&ResultObjects=Publication&PublicationContent=AllInfo&AuthorID=#{user.mas}&StartIdx=1&EndIdx=50"
    Rails.logger.info "Microsoft Academic Search query: #{url}"
    
    result = SourceHelper.get_json(url, options)["d"]["Publication"]
    return [] if result.nil?
    
    works = result["Result"]
  end

end