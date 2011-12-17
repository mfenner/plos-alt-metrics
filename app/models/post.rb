class Post < ActiveRecord::Base
  
  
  def body_with_links
    body.gsub(/(http:\/\/[a-zA-Z0-9\/\.\+\-_:?&=]+)/) {|a| "<a href=\"#{a}\" target='_blank'>#{a}</a>"}
  end
  
  def author_with_link
    "http://twitter.com/#{author}"
  end
end
