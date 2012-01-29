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

class BooksController < ApplicationController
  before_filter :authenticate_author!, :except => [ :index, :show ]

  # GET /books
  # GET /books.xml
  def index
    unless params[:q].blank?
      @books = Book.paginate :page => params[:page], 
        :per_page => 20,
        :conditions => ["books.title REGEXP ? or books.isbn_print REGEXP ? or books.isbn_electronic REGEXP ?", params[:q],params[:q],params[:q]],
        :order => 'books.title' 
    else
      if author_signed_in?
        # Fetch all books with the authors you are following
        #@books = Book.paginate :conditions => ["FIND_IN_SET(contributions.author_id, '?')",current_author.friends], :include => [:authors, :contributions], :page => params[:page], :per_page => 12
        @books = Book.paginate :page => params[:page], :per_page => 12, :order => 'books.title'
      else
        @books = Book.paginate :page => params[:page], :per_page => 12, :order => 'books.title'
      end
    end
    
    respond_to do |format|
      format.html do 
        if request.xhr?
          render :partial => "index" 
        end
      end
      format.xml  { render :xml => @books }
      format.json { render :json => @books, :callback => params[:callback] }
      format.csv  { render :csv => @books }
    end
  end

  # GET /books/1
  # GET /books/1.xml
  def show
    load_book
    
    respond_to do |format|
      format.html do 
        if request.xhr?
          render :partial => params[:partial] 
        else
          
        end
      end
      format.xml do
        response.headers['Content-Disposition'] = 'attachment; filename=' + params[:id].sub(/^info:/,'') + '.xml'
        render :xml => @book.book_articles.to_xml
      end
      format.csv  { render :csv => @book }
      format.json { render :json => @book.to_json, :callback => params[:callback] }
      format.bib { render :bib => @book }
      format.ris { render :ris => @book }
    end
  end

  # GET /books/new
  # GET /books/new.xml
  def new
    @book = Book.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @book }
      format.json { render :json => @book }
    end
  end
  
  # GET /books/1/edit
  def edit
    if request.xhr?
      render :partial => params[:partial]
    else
      render :show 
    end
  end

  # POST /books
  # POST /books.xml
  def create
    # Get book if it exists, otherwise create new one
    #@book = Book.find_or_initialize_by_mas(:mas  => params[:book][:mas])

    #respond_to do |format|
    #  if @book.save
    #    # Fetch book information and update book
    #    properties = Book.fetch_properties(@book)
    #    @book = Book.update_properties(@book, properties)
    #    flash[:notice] = 'Book was successfully created.' if @book.new_record?
    
    #    format.html { redirect_to book_path(@book.mas, :format => :html) }
    #    format.xml  { render :xml => @book, :status => :created, :location => @book }
    #    format.json { render :json => @book, :status => :created, :location => @book }
    #  else
    #    format.html { render :action => "new" }
    #    format.xml  { render :xml => @book.errors, :status => :unprocessable_entity }
    #    format.json { render :json => @book.errors, :status => :unprocessable_entity }
    #  end
    #end
  end

  # PUT /books/1
  # PUT /books/1.xml
  def update
    respond_to do |format|
      if @book.update_attributes(params[:book])
        flash[:notice] = 'Book was successfully updated.'
        format.html { render :partial => params[:partial] if request.xhr? }
        format.xml  { head :ok }
        format.json { head :ok }
      else
        format.html { render :partial => params[:partial] if request.xhr? }
        format.xml  { render :xml => @book.errors, :status => :unprocessable_entity }
        format.json { render :json => @book.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /books/1
  # DELETE /books/1.xml
  def destroy
    @book.destroy

    respond_to do |format|
      format.html { redirect_to(books_url) }
      format.xml  { head :ok }
      format.json { head :ok }
    end
  end

protected
  def load_book(options={})
    # Load one book given query params, for the non-#index actions
    # Use :username as :id
    @book = Book.find_by_isbn_print!(params[:id])
    if @book.nil?
      redirect_to :action => 'index' and return
    end
  end
end