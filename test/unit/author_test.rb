require 'test_helper'

class AuthorTest < ActiveSupport::TestCase
  def setup
    @author = Author.new :username => "carl"
  end

  def test_should_save
    assert @author.save
    assert @author.errors.empty?
  end

  def test_should_require_username
    @author.username = nil
    assert !@author.save, "Author should not be saved without a username"
  end

  def test_should_require_username_uniqueness
    assert @author.save
    @author2 = Author.new :username => "john"
    assert !@author2.save, "Username for author should be unique"
  end
end
