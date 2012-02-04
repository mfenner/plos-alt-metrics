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

class UsersControllerTest < ActionController::TestCase
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
    assert_not_nil assigns(:users)
  end

  def test_should_get_index_in_csv_format
    get_csv
    assert_equal @response.content_type, "text/csv"
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_user
    assert_difference('User.count') do
      post :create, :user => { :mas => "1" }
    end

    assert_redirected_to user_path(assigns(:user))
  end

  def test_should_require_mas
    post :create, :user => {}
    assert_tag :tag => "div", 
               :attributes => { :class => "fieldWithErrors" },
               :descendant => { :tag => "input", 
                                :attributes => { :id => "user_mas" } }
  end

  def test_should_show_user
    get :show, :id => users(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => users(:one).id
    assert_response :success
  end

  def test_should_update_user
    put :update, :id => users(:one).id, :user => { }
    assert_redirected_to user_path(assigns(:user))
  end

  def test_should_destroy_user
    assert_difference('User.count', -1) do
      delete :destroy, :id => users(:one).id
    end

    assert_redirected_to users_path
  end

  def test_should_route_formats
    %w/ xml csv json html /.each do |format|
      assert_routing "/users/#{users(:one).id}.#{format}", :controller => 'users', :action => 'show', :id => CGI.unescape(users(:one).id), :format => format
    end
    assert_routing "/users/#{users(:one).id}", :controller => 'users', :action => 'show', :id => CGI.unescape(users(:one).id)
  end

  def self.make_format_test(format_name, options={})
    format = options[:format] ||= format_name
    content_type = "application/#{options.delete(:type) || format}"
    define_method("test_should_generate_#{format_name}_format") do
      options[:id] = users(:one).id
      get :show, options
      assert_response :success
      assert_equal content_type, @response.content_type
      if format == "xml"
        result = parse_xml(@response.body)
        citations_count = result.find("//user").first.attributes["citations_count"]
      elsif format == "json"
        body = @response.body
        body = body[options[:callback].length+1..-2] \
          unless options[:callback].nil?
        citations_count = ActiveSupport::JSON.decode(body)["user"]["citations_count"]
      end
      assert citations_count
    end
  end
  make_format_test("xml")
  make_format_test("json")
  make_format_test("jsonp", :format => "json", :callback => "c",
    :type => "json")

end