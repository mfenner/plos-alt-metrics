require 'test_helper'

class AffiliationTest < ActiveSupport::TestCase
  def setup
    @affiliation = Affiliation.new :mas_id => "1"
  end

  def test_should_save
    assert @affiliation.save
    assert @affiliation.errors.empty?
  end

  def test_should_require_mas_id
    @affiliation.mas_id = nil
    assert !@affiliation.save
    assert @affiliation.errors.on(:mas_id)
  end

  def test_should_require_mas_id_uniqueness
    assert @affiliation.save
    @affiliation2 = Affiliation.new :mas_id => "1"
    assert !@affiliation2.save
    assert @affiliation2.errors.on(:mas_id)
  end
end
