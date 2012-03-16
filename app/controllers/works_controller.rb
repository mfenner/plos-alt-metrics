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

class WorksController < ApplicationController
  before_filter :authenticate_user!, :except => [ :index, :show ]
  before_filter :load_work, 
                :only => [ :edit, :update, :destroy ]
  
  def index
    redirect_to users_path
  end

  # GET /works/1
  # GET /works/1.xml
  def show
    load_work #load_work(eager_includes)
    
    if params[:refresh] == "now"
      Retriever.new(:lazy => false, :only_source => false).update(@work)      
    end

    format_options = params.slice :citations, :history, :source

    if params[:refresh] == "soon" or @work.stale?
      #uid = RetrievalWorker.async_retrieval(:work_id => @work.id)
      #logger.info "Queuing work #{@work.id} for retrieval as #{uid}"
    end
    
    respond_to do |format|
      format.html # show.html.erb
      format.mobile # show.mobile.erb
      format.js { render :show }
      format.xml do
        response.headers['Content-Disposition'] = 'attachment; filename=' + params[:id].sub(/^info:/,'') + '.xml'
        render :xml => @work.to_xml(format_options)
      end
      format.csv  { render :csv => @work }
      format.json { render :json => @work.to_json(format_options), :callback => params[:callback] }
      format.bib { render :bib => @work }
      format.ris { render :ris => @work }
    end
  end

  # GET /works/new
  # GET /works/new.xml
  def new
    @work = Work.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @work }
      format.json { render :json => @work }
    end
  end

  # POST /works
  # POST /works.xml
  def create
    # Set type to "Other" if no type is provided
    params[:work][:type] ||= "Other"
    
    @work = Work.new(params[:work])

    respond_to do |format|
      if @work.save
        flash[:notice] = 'Work was successfully created.'

        Source.all.each do |source|
          Retrieval.find_or_create_by_work_id_and_source_id(@work.id, source.id)
        end    

        format.html { redirect_to(@work) }
        format.xml  { render :xml => @work, :status => :created, :location => @work }
        format.json { render :json => @work, :status => :created, :location => @work }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @work.errors, :status => :unprocessable_entity }
        format.json { render :json => @work.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    
  end
  
  # PUT /works/1
  # PUT /works/1.xml
  def update
    respond_to do |format|
      if @work.update_attributes(params[:work])
        flash[:notice] = 'Work was successfully updated.'
        format.html { redirect_to(@work) }
        format.xml  { head :ok }
        format.json { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @work.errors, :status => :unprocessable_entity }
        format.json { render :json => @work.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /works/1
  # DELETE /works/1.xml
  def destroy
    @work.destroy

    respond_to do |format|
      format.html { redirect_to(works_url) }
      format.xml  { head :ok }
      format.json { head :ok }
    end
  end

protected
  def load_work(options={})
    # Load one work given query params, for the non-#index actions
    @work = Work.find(params[:id])
  end

  def eager_includes
    returning :include => { :retrievals => [ :source ] } do |r|
      r[:include][:retrievals] << :citations if params[:citations] == "1"
      r[:include][:retrievals] << :histories if params[:history] == "1"
      r[:conditions] = ['LOWER(sources.type) IN (?)', params[:source].downcase.split(",")] if params[:source]
    end
  end
end
