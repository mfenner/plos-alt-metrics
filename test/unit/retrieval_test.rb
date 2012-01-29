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

class RetrievalTest < ActiveSupport::TestCase
  def test_published_on_lazyness 
    # we shouldn't until the day after the publication date
    today = Date.new(2000,1,1)
    work = Work.create(:doi => "10.0/unpublished", 
                             :published_on => today)
    retriever = Retriever.new(:lazy => true)

    # First time we'll call it on the publication date - it should skip out.
    Date.stubs(:today).returns(today)
    Source.expects(:active).never
    retriever.update(work)

    # Second time we'll call it on the day after that - it should look for
    # sources.
    Date.stubs(:today).returns(today + 1)
    Source.expects(:active).returns([])
    retriever.update(work)
  end

  def test_citation_creation
    test_url = "http://dx.doi.org/10.0/citable"
    test_doi = "10.0/citable"
    work = Work.create(:url => test_url, :doi => test_doi, :type => "JournalArticle")
    source = sources(:pubmed)
    Source.expects(:active).returns([source])
    test_raw_citations = [
      %w[doi journal_title work_title uri].inject({}) do |h, k|
          h[k.intern] = k
          h
      end
    ]
    source.expects(:query).with(work, 
                                has_entries(:retrieval => "retrieval"))\
                          .returns(test_raw_citations)
  
    retrieval = work.retrievals.first(:conditions => { :source_id => source.id })
    doomed_citation = Citation.new(:retrieval => retrieval,
                                   :uri => "bogus")
    doomed_citation.save!

    # Before
    assert_equal [doomed_citation], retrieval.citations
    assert_equal work.citations_count, 1
    assert work.retrieved_at < 1.years.ago

    # Do it
    Retriever.new({}).update(work)

    # After
    citations = Citation.find_all_by_uri("uri")
    assert_equal citations.size, 1
    citation = citations.first
    assert_equal retrieval.reload.citations, citations
    assert_equal work.reload.citations, citations
    assert_equal work.citations_count, 1
    assert work.retrieved_at > 2.seconds.ago
    assert_equal citation.retrieval, retrieval
  end
end
