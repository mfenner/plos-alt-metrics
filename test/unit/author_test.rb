require 'test_helper'

class AuthorTest < ActiveSupport::TestCase
  def setup
    @author = Author.new :mas_id => "1"
  end

  def test_should_save
    assert @author.save
    assert @author.errors.empty?
  end

  def test_should_require_mas_id
    @author.mas_id = nil
    assert !@author.save
    assert @author.errors.on(:mas_id)
  end

  def test_should_require_mas_id_uniqueness
    assert @author.save
    @author2 = Author.new :mas_id => "1"
    assert !@author2.save
    assert @author2.errors.on(:mas_id)
  end
end
