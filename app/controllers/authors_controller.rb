# Copyright (c) 2011 Martin Fenner
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

class AuthorsController < ApplicationController
  before_filter :login_required, :except => [ :index, :show, :search ]

  # GET /authors
  # GET /authors.xml
  def index
    @authors = Author.paginate :page => params[:page], :per_page => 10, :order => 'sort_name'
    
    respond_to do |format|
      format.html { render :partial => "index" if request.xhr? }
      format.xml  { render :xml => @authors }
      format.json { render :json => @authors, :callback => params[:callback] }
      format.csv  { render :csv => @authors }
    end
  end

  # GET /authors/1
  # GET /authors/1.xml
  def show
    if params[:refresh] == "now"
      load_author    
      redirect_to(@author) and return  # why not just keep going with show?
    end

    load_author
    
    @articles = @author.articles.paginate :page => params[:page], :per_page => 10, :include => :retrievals, :order => "retrievals.citations_count desc, articles.year desc"
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml do
        response.headers['Content-Disposition'] = 'attachment; filename=' + params[:id].sub(/^info:/,'') + '.xml'
        render :xml => @author.articles.to_xml
      end
      format.csv  { render :csv => @author }
      format.json { render :json => @author.articles, :callback => params[:callback] }
    end
  end

  # GET /authors/new
  # GET /authors/new.xml
  def new
    @author = Author.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @author }
      format.json { render :json => @author }
    end
  end
  
  # GET /authors/1/edit
  def edit
    @author = Author.find_by_mas_id(params[:id])
  end

  # POST /authors
  # POST /authors.xml
  def create
    # Get author if it exists, otherwise create new one
    @author = Author.find_or_initialize_by_mas_id(:mas_id  => params[:author][:mas_id])

    respond_to do |format|
      if @author.save
        # Fetch author information and update author
        properties = Author.fetch_properties(@author)
        @author = Author.update_properties(@author, properties)
        flash[:notice] = 'Author was successfully created.' if @author.new_record?

        format.html { redirect_to author_path(@author.mas_id, :format => :html) }
        format.xml  { render :xml => @author, :status => :created, :location => @author }
        format.json { render :json => @author, :status => :created, :location => @author }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @author.errors, :status => :unprocessable_entity }
        format.json { render :json => @author.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /authors/1
  # PUT /authors/1.xml
  def update
    respond_to do |format|
      if @author.update_attributes(params[:author])
        flash[:notice] = 'Author was successfully updated.'
        format.html { redirect_to(@author) }
        format.xml  { head :ok }
        format.json { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @author.errors, :status => :unprocessable_entity }
        format.json { render :json => @author.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /authors/1
  # DELETE /authors/1.xml
  def destroy
    @author.destroy

    respond_to do |format|
      format.html { redirect_to(authors_url) }
      format.xml  { head :ok }
      format.json { head :ok }
    end
  end
  
  def search
    unless params[:search].blank?
      @authors = Author.paginate :page => params[:page], 
        :per_page => 10,
        :conditions => ["authors.name REGEXP ? or authors.mas_id REGEXP ? or affiliations.name REGEXP ?", params['search'],params['search'],params['search']],
        :include => :affiliations,
        :order => 'authors.sort_name' 
    else
      redirect_to :action => :index and return
    end
    if request.xhr?
      render :partial => 'index'
    else
      render :index
    end
  end

protected
  def load_author(options={})
    # Load one author given query params, for the non-#index actions
    mas_id = params[:id]
    @author = Author.find_by_mas_id!(mas_id, options)
  end
end
