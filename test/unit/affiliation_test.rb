require 'test_helper'

class AffiliationTest < ActiveSupport::TestCase
  def setup
    @affiliation = Affiliation.new :mas => "3"
  end

  def test_should_save
    assert @affiliation.save
    assert @affiliation.errors.empty?
  end

  def test_should_require_mas
    @affiliation.mas = nil
    assert !@affiliation.save, "affiliation should not be saved without mas"
  end

  def test_should_require_mas_uniqueness
    assert @affiliation.save
    @affiliation2 = Affiliation.new :mas => "1"
    assert !@affiliation2.save, "mas for affiliation should be unique"
  end
end
