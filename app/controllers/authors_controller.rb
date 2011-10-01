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
  before_filter :authenticate_author!, :except => [ :index, :show ]
  before_filter :load_author, 
                :only => [ :edit, :update, :destroy ]

  # GET /authors
  # GET /authors.xml
  def index
    unless params[:q].blank?
      @authors = Author.paginate :page => params[:page], 
        :per_page => 12,
        :conditions => ["authors.name REGEXP ? or authors.username REGEXP ? or authors.native_name REGEXP ? or authors.mas REGEXP ?", params[:q],params[:q],params[:q],params[:q]],
        :order => 'authors.sort_name, authors.username' 
    else
      if author_signed_in?
        @authors = Author.paginate :page => params[:page], :per_page => 12, :order => 'sort_name, username'
      else
        @authors = []
      end
    end
    
    respond_to do |format|
      format.html do 
        if request.xhr?
          render :partial => "index" 
        end
      end
      format.xml  { render :xml => @authors }
      format.json { render :json => @authors, :callback => params[:callback] }
      format.csv  { render :csv => @authors }
    end
  end

  # GET /authors/1
  # GET /authors/1.xml
  def show
    load_author
    @articles = @author.articles.paginate :page => params[:page], :per_page => 10, :include => :retrievals, :order => "IF(articles.published_on IS NULL, articles.year, articles.published_on) desc"
    
    respond_to do |format|
      format.html do 
        if request.xhr?
          render :partial => params[:partial] 
        else
          
        end
      end
      format.xml do
        response.headers['Content-Disposition'] = 'attachment; filename=' + params[:id].sub(/^info:/,'') + '.xml'
        render :xml => @author.articles.to_xml
      end
      format.csv  { render :csv => @author }
      format.json { render :json => @author.to_json, :callback => params[:callback] }
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
    @articles = @author.articles.paginate :page => params[:page], :per_page => 10, :order => "IF(articles.published_on IS NULL, articles.year, articles.published_on) desc"
    if request.xhr?
      render :partial => params[:partial]
    else
      render :show 
    end
  end

  # POST /authors
  # POST /authors.xml
  def create
    # Get author if it exists, otherwise create new one
    #@author = Author.find_or_initialize_by_mas(:mas  => params[:author][:mas])

    #respond_to do |format|
    #  if @author.save
    #    # Fetch author information and update author
    #    properties = Author.fetch_properties(@author)
    #    @author = Author.update_properties(@author, properties)
    #    flash[:notice] = 'Author was successfully created.' if @author.new_record?
    
    #    format.html { redirect_to author_path(@author.mas, :format => :html) }
    #    format.xml  { render :xml => @author, :status => :created, :location => @author }
    #    format.json { render :json => @author, :status => :created, :location => @author }
    #  else
    #    format.html { render :action => "new" }
    #    format.xml  { render :xml => @author.errors, :status => :unprocessable_entity }
    #    format.json { render :json => @author.errors, :status => :unprocessable_entity }
    #  end
    #end
  end

  # PUT /authors/1
  # PUT /authors/1.xml
  def update
    @articles = @author.articles.paginate :page => params[:page], :per_page => 10, :order => "IF(articles.published_on IS NULL, articles.year, articles.published_on) desc"
  
    respond_to do |format|
      if @author.update_attributes(params[:author])
        if params[:partial] == "mas"
          # Fetch articles from author, return nil if no response
          results = Author.fetch_articles(@author)
          # First remove all claimed articles, e.g. because mas id was changed or set to empty 
          @author.contributions.clear
          unless results.empty?
            results.each do |result|
              # Only add articles with DOI and title
              unless result["DOI"].nil? or result["Title"].nil?
                article = Article.find_or_create_by_doi(:doi => result["DOI"], :mas => result["ID"], :title => result["Title"], :year => result["Year"])
                # Check that DOI is valid
                if article.valid?
                  @author.articles << article unless @author.articles.include?(article)
                end
              end
            end
          end
        end
        #flash[:notice] = 'Author was successfully updated.'
        format.html do
          if request.xhr? 
            service_partial = render_to_string(:partial => params[:partial])
            article_partial = render_to_string(:partial => 'article')

            render :update do |page|
              page.replace params[:partial], service_partial
              page.replace 'article', article_partial
            end
          end
        end
        format.xml  { head :ok }
        format.json { head :ok }
      else
        format.html { render :partial => params[:partial] if request.xhr? }
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
    # Use :username as :id
    @author = Author.find_by_username!(params[:id], options)
    if @author.nil?
      redirect_to :action => 'index' and return
    end
  end
end