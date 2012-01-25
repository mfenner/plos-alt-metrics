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

class WorksControllerTest < ActionController::TestCase
  include Fetcher

  def setup
    login_as(:quentin)
  end

  def get_csv(options={})
    get :index, options.merge(:format => "csv")
    assert_response :success
    @response.body.split("\n")[1..-1].map { |r| r.split(',') }
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:works)
  end

  def test_should_get_index_in_csv_format
    get_csv
    assert_equal @response.content_type, "text/csv"
  end

  def test_should_order_by_doi_by_default
    dois = get_csv.map { |a| a[0] }
    assert_equal dois.sort, dois
  end

  def test_should_order_by_doi_by_published_on
    results = get_csv :order => "published_on"
    assert results[0][0] == works(:stale).doi
    assert results[1][0] == works(:not_stale).doi
  end

  def test_should_get_only_cited_works
    results = get_csv :cited => "1"
    assert_equal Work.cited(1).count, results.size
    assert_equal Work.cited(1).collect(&:doi), results.collect(&:first)
  end

  def test_should_get_only_uncited_works
    results = get_csv :cited => "0"
    assert_equal Work.cited(0).count, results.size
    assert_equal Work.cited(0).collect(&:doi), results.collect(&:first)
  end

  def test_should_include_source_counts
    results = get_csv
    a, b = works(:not_stale), works(:stale)
    assert_equal [a.doi, a.published_on.to_s, a.title.to_s.strip_tags, "0", "1"], results[0]
    assert_equal [b.doi, b.published_on.to_s, b.title.to_s.strip_tags, "1", "1"], results[1]
  end

  def test_should_filter_by_query
    results = get_csv :query => "pgen"
    assert results.size == 1
    assert results[0][0] == works(:stale).doi
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_work
    assert_difference('Work.count') do
      post :create, :work => { :doi => "10.0/dummy" }
    end

    assert_redirected_to work_path(assigns(:work))
  end

  def test_should_work_with_arbitrary_dois
    assert_difference('Work.count', 5) do
      post :create, :work => { :doi => "10.1000/182" }
      post :create, :work => { :doi => "10.0092/ooh" }
      post :create, :work => { :doi => "10.10/♥" }
      post :create, :work => { :doi => "1.0/1337" }
      post :create, :work => { :doi => "10.9898098098098/นก" }
    end
  end

  def test_should_require_doi
    post :create, :work => {}
    assert_tag :tag => "div", 
               :attributes => { :class => "fieldWithErrors" },
               :descendant => { :tag => "input", 
                                :attributes => { :id => "work_doi" } }
  end

  def test_should_show_work
    get :show, :id => work_one_id
    assert_response :success
  end

  def test_should_show_work_csv_sources
    get :show, :id => works(:stale).doi, :format => 'csv'
    assert @response.body =~ /citeulike/i
    assert @response.body =~ /pubmed/i
  end

  def test_should_show_work_csv_sources_citeulike
    get :show, :id => works(:stale).doi, :format => 'csv', :source => 'citeulike'
    assert @response.body =~ /citeulike/i
    assert @response.body !~ /pubmed/i
  end

  def test_should_show_work_csv_sources_pubmed
    get :show, :id => works(:stale).doi, :format => 'csv', :source => 'pubmed'
    assert @response.body !~ /citeulike/i
    assert @response.body =~ /pubmed/i, @response.body
  end

  def test_should_get_edit
    get :edit, :id => work_one_id
    assert_response :success
  end

  def test_should_update_work
    put :update, :id => work_one_id, :work => { }
    assert_redirected_to work_path(assigns(:work))
  end

  def test_should_destroy_work
    assert_difference('Work.count', -1) do
      delete :destroy, :id => work_one_id
    end

    assert_redirected_to works_path
  end

  def test_should_generate_route_using_doi
    # This ought to be as simple as:
    #   path = "works/info:doi%2F10.1000%2Fjournal.pone.1000/edit"
    #   opts = {:controller => "works", 
    #           :id => "info:doi/10.1000/journal.pone.1000", 
    #           :action => "edit"}
    #   assert_generates path, opts
    # but that fails, complaining that it can't find a route using
    # the DOI in the @opts hash. If I escape the DOI, it
    # finds the route but ends up double-escaping the URI, which causes
    # the comparison to fail. By doing extra escaping in the path, it passes:
    path = "works/info:doi%252F10.1000%252Fjournal.pone.1000/edit"
    opts = {:controller => "works", :id => "info:doi%2F10.1000%2Fjournal.pone.1000", :action => "edit"}
    assert_generates path, opts
  end

  def test_should_recognize_route_using_doi
    path = "works/info:doi%2F10.1000%2Fjournal.pone.1000/edit"
    opts = {:controller => "works", :id => "info:doi/10.1000/journal.pone.1000", :action => "edit"}
    assert_recognizes opts, path
  end

  def test_should_route_formats
    %w/ xml csv json html /.each do |format|
      assert_routing "/works/#{work_one_id}.#{format}", :controller => 'works', :action => 'show', :id => CGI.unescape(work_one_id), :format => format
    end
    assert_routing "/works/#{work_one_id}", :controller => 'works', :action => 'show', :id => CGI.unescape(work_one_id)
  end

  def self.make_format_test(format_name, options={})
    format = options[:format] ||= format_name
    content_type = "application/#{options.delete(:type) || format}"
    define_method("test_should_generate_#{format_name}_format") do
      options[:id] = work_one_id
      get :show, options
      assert_response :success
      assert_equal content_type, @response.content_type
      if format == "xml"
        result = parse_xml(@response.body)
        citations_count = result.find("//work").first.attributes["citations_count"]
      elsif format == "json"
        body = @response.body
        body = body[options[:callback].length+1..-2] \
          unless options[:callback].nil?
        citations_count = ActiveSupport::JSON.decode(body)["work"]["citations_count"]
      end
      assert citations_count
    end
  end
  make_format_test("xml")
  make_format_test("xml_with_citations", :format => "xml", :citations => "1")
  make_format_test("xml_with_history", :format => "xml", :history => "1")
  make_format_test("json")
  make_format_test("jsonp", :format => "json", :callback => "c",
    :type => "json")
  make_format_test("jsonp_with_citations", :format => "json", :callback => "c",
    :type => "json", :citations => "1")
  make_format_test("jsonp_with_history", :format => "json", :callback => "c",
    :type => "json", :history => "1")

private
  def work_one_id
    works(:not_stale).to_param.gsub("/", "%2F")
  end
end
