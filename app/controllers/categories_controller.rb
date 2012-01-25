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

class CategoriesController < ApplicationController
  before_filter :authenticate_author!

  #This is a way of excepting a list of DOIS and getting back summaries for them all.
  #Works with no cites are not returned
  #This method does not check for work staleness and does not query works for refresh
  def category_work_summaries
    logger.debug "categoryWorkSummaries"

    #Specifying multilple DOIS without a parameter proved nightmareish
    #So we do it here using a comma delimated list with format 
    #Specified as a parameter (ID)

    #Here sometimes the :format value may have a period attached to it
    #This will filter it out
    reqFormat = params[:format]

    if reqFormat != nil
      matchedFormat = reqFormat.match(/xml|csv|json/)
      
      #If we get a bad format, just default to nil (or HTML)
      if matchedFormat == nil
        request.format = nil
      else
        request.format = matchedFormat[0]
        logger.info "format:" + request.format
      end
    end

    logger.info "ID:" + params[:id]

    if !params[:id]
      raise "ID parameter not specified"
    end

    #Ids can be a collection
    ids = params[:id].split(',')
    ids = ids.map { |id| DOI::from_uri(id) }
      
    @result  = []

    # Specifiy the eager loading so we get all the data we need up front
    works = Work.find(:all, 
      :include => [ :retrievals => [ :citations, { :source => :category } ]], 
      :conditions => [ "works.doi in (?) and (retrievals.citations_count > 0 or retrievals.other_citations_count > 0)", ids ])
    
    @result = works.map do |work|
      returning Hash.new do |hash|
        hash[:work] = work
        hash[:categorycounts] = work.citations_by_category
        
        # If any categories are specified via URL params, get those details
        hash[:categories] = params[:category].split(",").map do |category|
          sources = work.get_cites_by_category(category)
          { :name => category,
            :sources => sources } unless sources.empty?
        end.compact if params[:category]
      end
    end
  
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @result }
      format.json { render :json => @result, :callback => params[:callback] }
    end
  end

  # GET /categories
  def index
    @categories = Category.find(:all)

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /categories/1
  def show
    @category = Category.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
    end
  end

  # GET /categories/new
  def new
    @category = Category.new
    
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /categories/1/edit
  def edit
    @category = Category.find(params[:id])
  end

  # POST /categories
  def create
    @category = Category.new(params[:category])

    respond_to do |format|
      if @category.save
        flash[:notice] = 'Category was successfully created.'
        format.html { redirect_to(categories_url) }
      else
        format.html { render :action => "new" }
      end
    end
  end

  # POST /categories/1
  def update
    @category = Category.find(params[:id])

    respond_to do |format|
      if @category.update_attributes(params[:category])
        flash[:notice] = 'Category was successfully updated.'
        format.html { redirect_to(categories_url) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /categories/1
  def destroy
    @category = Category.find(params[:id])
    
    Source.find(:all, :conditions => {  :category_id => @category.id }).each do |s| 
      s.category = nil;
      s.save
    end
    
    @category.destroy

    respond_to do |format|
      format.html { redirect_to(categories_url) }
    end
  end

end