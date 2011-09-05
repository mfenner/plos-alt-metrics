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
  before_filter :login_required, :except => [ :index, :show ]

  # GET /authors
  # GET /authors.xml
  def index

    @authors = Author.paginate :page => params[:page], :per_page => params[:per_page]

    respond_to do |format|
      format.html
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
    @author = Author.new(params[:author])

    respond_to do |format|
      if @author.save
        flash[:notice] = 'Author was successfully created.'

        #Source.all.each do |source|
         # Retrieval.find_or_create_by_author_id_and_source_id(@author.id, source.id)
        #end    

        format.html { redirect_to authors_path }
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

protected
  def load_author(options={})
    # Load one author given query params, for the non-#index actions
    mas_id = params[:id]
    @author = Author.find_by_mas_id!(mas_id, options)
  end
end
