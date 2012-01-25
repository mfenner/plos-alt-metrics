# $HeadURL$
# $Id$
#
# Copyright (c) 2009-2010 by Public Library of Science, a non-profit corporation
# http://www.plos.org/
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'test_helper'

class WorkTest < ActiveSupport::TestCase
  def setup
    @work = Work.new :doi => "10.0/dummy"
  end

  def test_should_save
    assert @work.save
    assert @work.errors.empty?
  end

  def test_should_require_doi
    @work.doi = nil
    assert !@work.save, "work should not be saved without a DOI"
  end

  def test_should_require_doi_uniqueness
    assert @work.save
    @work2 = Work.new :doi => "10.0/dummy"
    assert !@work2.save, "work requires unique DOI"
  end

  def test_should_find_stale_works
    assert_equal [works(:uncited_with_no_retrievals), works(:stale), works(:not_stale)],
      Work.stale_and_published
  end

  def test_should_be_stale_based_on_retrieval_age
    check_staleness(works(:stale)) { |a| a.retrievals.first.update_attribute :retrieved_at, 2.years.ago }
  end

  def test_staleness_on_new
    a = Work.new
    assert a.errors.empty?
    assert a.stale?
  end

  def test_staleness_on_create
    a = Work.create :doi => '10.1/foo'
    assert a.valid?, a.errors.full_messages
    assert a.stale?

    a.published_on = 1.day.ago
    assert a.save
    assert Work.stale_and_published.include?(a)
  end

  def test_retrievals_created_on_newly_created_work
    a = Work.create :doi => '10.1/foo'
    assert a.valid?, a.errors.full_messages
    assert_equal Source.active.count, a.retrievals.count
  end

  def test_staleness_excludes_failed_retrievals
    a = Work.create :doi => '10.1/foo', :published_on => 1.day.ago
    assert a.valid?, a.errors.full_messages
    assert a.stale?

    r = a.retrievals.first(:conditions => { :source_id => sources(:citeulike).id })
    assert r.valid?
    assert_equal Time.at(0), r.retrieved_at
    assert Work.stale_and_published.include?(a)
  end

  def test_staleness_excludes_disabled_sources
    assert_equal 3, Work.stale_and_published.count
    Source.update_all :disable_until => 3.days.from_now
    assert_equal [], Work.stale_and_published
    Source.update_all :disable_until => 1.second.ago
    assert_equal 3, Work.stale_and_published.count
  end

  def test_staleness_excludes_failed_retrievals_and_disabled_sources
    a = Work.create! :doi => '10.1/foo', :published_on => 1.day.ago
    r = a.retrievals.first(:conditions => { :source_id => sources(:citeulike).id })
    assert_equal Time.at(0), r.retrieved_at
    Source.update_all :disable_until => 3.days.from_now

    assert !Work.stale_and_published.include?(a)
  end

  def test_cited
    cited = Work.cited(1)
    assert cited.size > 0
    cited.each do |a|
      assert a.citations_count > 0
    end
  end

  def test_uncited
    uncited = Work.cited(0)
    assert uncited.size > 0
    uncited.each do |a|
      assert_equal 0, a.citations_count
    end
  end

  def test_cited_consistency
    assert_equal Work.count, Work.cited(1).count + Work.cited(0).count
    assert_equal Work.count, Work.cited(nil).count
    assert_equal Work.count, Work.cited('blah').count
  end

  def check_staleness(work, &block)
    work.update_attribute :retrieved_at, 1.minute.ago
    work.retrievals.each {|r| r.update_attribute :retrieved_at, 1.minute.ago }
    assert !work.stale?
    yield work
    assert work.stale?
  end
end
