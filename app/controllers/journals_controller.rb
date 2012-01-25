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

class JournalsController < ApplicationController
  before_filter :authenticate_author!, :except => [ :index, :show ]

  # GET /journals
  # GET /journals.xml
  def index
    unless params[:q].blank?
      @journals = Journal.paginate :page => params[:page], 
        :per_page => 20,
        :conditions => ["journals.title REGEXP ? or journals.issn_print REGEXP ? or journals.issn_print REGEXP ?", params[:q],params[:q],params[:q]],
        :order => 'journals.title' 
    else
      if author_signed_in?
        # Fetch all journals with the authors you are following
        #@journals = Journal.paginate :conditions => ["FIND_IN_SET(contributions.author_id, '?')",current_author.friends], :include => [:authors, :contributions], :page => params[:page], :per_page => 12
        @journals = Journal.paginate :page => params[:page], :per_page => 12, :order => 'journals.title'
      else
        @journals = Journal.paginate :page => params[:page], :per_page => 12, :order => 'journals.title'
      end
    end
    
    respond_to do |format|
      format.html do 
        if request.xhr?
          render :partial => "index" 
        end
      end
      format.xml  { render :xml => @journals }
      format.json { render :json => @journals, :callback => params[:callback] }
      format.csv  { render :csv => @journals }
    end
  end

  # GET /journals/1
  # GET /journals/1.xml
  def show
    load_journal
    @works = @journal.works.paginate :page => params[:page], :per_page => 20, :include => :retrievals, :order => "retrievals.citations_count desc, works.year desc"
    
    respond_to do |format|
      format.html do 
        if request.xhr?
          render :partial => params[:partial] 
        else
          
        end
      end
      format.xml do
        response.headers['Content-Disposition'] = 'attachment; filename=' + params[:id].sub(/^info:/,'') + '.xml'
        render :xml => @journal.works.to_xml
      end
      format.csv  { render :csv => @journal }
      format.json { render :json => @journal.to_json, :callback => params[:callback] }
      format.bib { render :bib => @journal }
      format.ris { render :ris => @journal }
    end
  end

  # GET /journals/new
  # GET /journals/new.xml
  def new
    @journal = Journal.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @journal }
      format.json { render :json => @journal }
    end
  end
  
  # GET /journals/1/edit
  def edit
    @works = @journal.works.paginate :page => params[:page], :per_page => 20, :include => :retrievals, :order => "retrievals.citations_count desc, works.year desc"
    if request.xhr?
      render :partial => params[:partial]
    else
      render :show 
    end
  end

  # POST /journals
  # POST /journals.xml
  def create
    # Get journal if it exists, otherwise create new one
    #@journal = Journal.find_or_initialize_by_mas(:mas  => params[:journal][:mas])

    #respond_to do |format|
    #  if @journal.save
    #    # Fetch journal information and update journal
    #    properties = Journal.fetch_properties(@journal)
    #    @journal = Journal.update_properties(@journal, properties)
    #    flash[:notice] = 'Journal was successfully created.' if @journal.new_record?
    
    #    format.html { redirect_to journal_path(@journal.mas, :format => :html) }
    #    format.xml  { render :xml => @journal, :status => :created, :location => @journal }
    #    format.json { render :json => @journal, :status => :created, :location => @journal }
    #  else
    #    format.html { render :action => "new" }
    #    format.xml  { render :xml => @journal.errors, :status => :unprocessable_entity }
    #    format.json { render :json => @journal.errors, :status => :unprocessable_entity }
    #  end
    #end
  end

  # PUT /journals/1
  # PUT /journals/1.xml
  def update
    respond_to do |format|
      if @journal.update_attributes(params[:journal])
        flash[:notice] = 'Journal was successfully updated.'
        format.html { render :partial => params[:partial] if request.xhr? }
        format.xml  { head :ok }
        format.json { head :ok }
      else
        format.html { render :partial => params[:partial] if request.xhr? }
        format.xml  { render :xml => @journal.errors, :status => :unprocessable_entity }
        format.json { render :json => @journal.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /journals/1
  # DELETE /journals/1.xml
  def destroy
    @journal.destroy

    respond_to do |format|
      format.html { redirect_to(journals_url) }
      format.xml  { head :ok }
      format.json { head :ok }
    end
  end

protected
  def load_journal(options={})
    # Load one journal given query params, for the non-#index actions
    # Use :username as :id
    @journal = Journal.find_by_issn_print!(params[:id])
    if @journal.nil?
      redirect_to :action => 'index' and return
    end
  end
end