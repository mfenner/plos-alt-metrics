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

class AffiliationsControllerTest < ActionController::TestCase
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
    assert_not_nil assigns(:affiliations)
  end

  def test_should_get_index_in_csv_format
    get_csv
    assert_equal @response.content_type, "text/csv"
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_affiliation
    assert_difference('Affiliation.count') do
      post :create, :affiliation => { :mas => "1" }
    end

    assert_redirected_to affiliation_path(assigns(:affiliation))
  end

  def test_should_require_mas
    post :create, :affiliation => {}
    assert_tag :tag => "div", 
               :attributes => { :class => "fieldWithErrors" },
               :descendant => { :tag => "input", 
                                :attributes => { :id => "affiliation_mas" } }
  end

  def test_should_show_affiliation
    get :show, :id => affiliation_one_id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => affiliation_one_id
    assert_response :success
  end

  def test_should_update_affiliation
    put :update, :id => affiliation_one_id, :affiliation => { }
    assert_redirected_to affiliation_path(assigns(:affiliation))
  end

  def test_should_destroy_affiliation
    assert_difference('Affiliation.count', -1) do
      delete :destroy, :id => affiliation_one_id
    end

    assert_redirected_to affiliations_path
  end

  def test_should_route_formats
    %w/ xml csv json html /.each do |format|
      assert_routing "/affiliations/#{affiliation_one_id}.#{format}", :controller => 'affiliations', :action => 'show', :id => CGI.unescape(affiliation_one_id), :format => format
    end
    assert_routing "/affiliations/#{affiliation_one_id}", :controller => 'affiliations', :action => 'show', :id => CGI.unescape(affiliation_one_id)
  end

  def self.make_format_test(format_name, options={})
    format = options[:format] ||= format_name
    content_type = "application/#{options.delete(:type) || format}"
    define_method("test_should_generate_#{format_name}_format") do
      options[:id] = affiliation_one_id
      get :show, options
      assert_response :success
      assert_equal content_type, @response.content_type
      if format == "xml"
        result = parse_xml(@response.body)
        citations_count = result.find("//affiliation").first.attributes["citations_count"]
      elsif format == "json"
        body = @response.body
        body = body[options[:callback].length+1..-2] \
          unless options[:callback].nil?
        citations_count = ActiveSupport::JSON.decode(body)["affiliation"]["citations_count"]
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
  def affiliation_one_id
    affiliations(:not_stale).to_param.gsub("/", "%2F")
  end
end