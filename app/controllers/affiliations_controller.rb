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

class AffiliationsController < ApplicationController
  before_filter :login_required, :except => [ :index, :show, :search ]
  
  require "will_paginate"

  # GET /affiliations
  # GET /affiliations.xml
  def index
    @affiliations = Affiliation.paginate :page => params[:page], :per_page => 10, :order => 'name'

    respond_to do |format|
      format.html 
      format.xml  { render :xml => @affiliations }
      format.json { render :json => @affiliations, :callback => params[:callback] }
      format.csv  { render :csv => @affiliations }
    end
  end

  # GET /affiliations/1
  # GET /affiliations/1.xml
  def show
    if params[:refresh] == "now"
      load_affiliation    
      redirect_to(@affiliation) and return  # why not just keep going with show?
    end

    load_affiliation

    respond_to do |format|
      format.html # show.html.erb
      format.xml do
        response.headers['Content-Disposition'] = 'attachment; filename=' + params[:id].sub(/^info:/,'') + '.xml'
        render :xml => @affiliation.authors.to_xml
      end
      format.csv  { render :csv => @affiliation }
      format.json { render :json => @affiliation.authors, :callback => params[:callback] }
    end
  end

  # GET /affiliations/new
  # GET /affiliations/new.xml
  def new
    @affiliation = Affiliation.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @affiliation }
      format.json { render :json => @affiliation }
    end
  end

  # GET /affiliations/1/edit
  def edit
    @affiliation = Affiliation.find_by_mas_id(params[:id])
  end

  # POST /affiliations
  # POST /affiliations.xml
  def create
    @affiliation = Affiliation.new(params[:affiliation])

    respond_to do |format|
      if @affiliation.save

        # Fetch affiliation information and update affiliation
        @affiliation = Affiliation.update_properties(@affiliation)
        flash[:notice] = 'Affiliation was successfully created.'

        #Source.all.each do |source|
         # Retrieval.find_or_create_by_affiliation_id_and_source_id(@affiliation.id, source.id)
        #end    

        format.html { redirect_to affiliation_path(@affiliation.mas_id) }
        format.xml  { render :xml => @affiliation, :status => :created, :location => @affiliation }
        format.json { render :json => @affiliation, :status => :created, :location => @affiliation }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @affiliation.errors, :status => :unprocessable_entity }
        format.json { render :json => @affiliation.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /affiliations/1
  # PUT /affiliations/1.xml
  def update
    respond_to do |format|
      if @affiliation.update_attributes(params[:affiliation])
        flash[:notice] = 'Affiliation was successfully updated.'
        format.html { redirect_to(@affiliation) }
        format.xml  { head :ok }
        format.json { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @affiliation.errors, :status => :unprocessable_entity }
        format.json { render :json => @affiliation.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /affiliations/1
  # DELETE /affiliations/1.xml
  def destroy
    @affiliation.destroy

    respond_to do |format|
      format.html { redirect_to(affiliations_url) }
      format.xml  { head :ok }
      format.json { head :ok }
    end
  end
  
  def search
    unless params[:search].blank?
      @affiliations = Affiliation.paginate :page => params[:page], 
        :per_page => 10,
        :conditions => ["CONCAT(authors.name, ' ', authors.mas_id, ' ', affiliations.name) REGEXP ?", params['search']],
        :include => :authors,
        :order => 'affiliations.name' 
    else
      index
    end
    if request.xhr?
      render :partial => 'index'
    else
      render :index
    end
  end

protected
  def load_affiliation(options={})
    # Load one affiliation given query params, for the non-#index actions
    mas_id = params[:id]
    @affiliation = Affiliation.find_by_mas_id!(mas_id, options)
  end
end