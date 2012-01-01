class Post < ActiveRecord::Base
  has_many :ratings
  has_many :authors, :through => :ratings
  
  def body_with_links
    body.gsub(/(http:\/\/[a-zA-Z0-9\/\.\+\-_:?&=]+)/) {|a| "<a href=\"#{a}\">#{a}</a>"}
  end
  
  def body_with_one_link
    body.sub(/(http:\/\/[a-zA-Z0-9\/\.\+\-_:?&=]+)/) {|a| "<a href=\"#{a}\">#{a}</a>"}
  end
  
  def author_with_link
    "http://twitter.com/#{author}"
  end
  
  def article_title_and_journal
    return "" if article_title.blank?
    "Title of article: " + article_title + "." + ((journal_title.blank? or journal_title == "0") ? "" : " Published in " + journal_title + ".")
  end
  
  def rhetoric
    agrees_with = ratings.inject(0) {|sum, rating| sum + (rating.rhetoric == "agreesWith" ? 1 : 0) }
    discusses = ratings.inject(0) {|sum, rating| sum + (rating.rhetoric == "discusses" ? 1 : 0) }
    disagrees_with = ratings.inject(0) {|sum, rating| sum + (rating.rhetoric == "disagreesWith" ? 1 : 0) }
    rhetoric = { "Agrees with " => agrees_with, "Discusses " => discusses, "Disagrees with" => disagrees_with }.max {|a,b| a[1] <=> b[1]}
    rhetoric[0] + " the cited paper.<br />"
  end
  
  def is_author
    if ratings.any? {|rating| rating.is_author }
      "Written by an author or publisher of the cited paper.<br />"
    else
      nil
    end
  end
  
  def method
    if ratings.any? {|rating| rating.method }
      "Describes a method detailed in the cited paper.<br />"
    else
      nil
    end
  end
  
  def data
    if ratings.any? {|rating| rating.data }
      "Uses data presented in the cited paper.<br />"
    else
      nil
    end
  end
  
  def conclusions
    if ratings.any? {|rating| rating.conclusions }
      "Describes conclusions presented in the cited paper.<br />"
    else
      nil
    end
  end
  
  def spam
    if ratings.any? {|rating| rating.spam }
      true
    else
      false
    end
  end
end
