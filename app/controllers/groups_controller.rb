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

class GroupsController < ApplicationController
  before_filter :authenticate_group!, :except => [ :index, :show ]
  before_filter :load_group, 
                :only => [ :edit, :update, :destroy ]

  # GET /groups
  # GET /groups.xml
  def index
    unless params[:q].blank?
      @groups = Group.paginate :page => params[:page], 
        :per_page => 20,
        :conditions => ["groups.name REGEXP ? or groups.mendeley REGEXP ?", params[:q],params[:q]],
        :order => 'groups.name' 
    else
      if author_signed_in?
        # Fetch all groups with the authors you are following
        #@groups = Group.paginate :conditions => ["FIND_IN_SET(contributions.author_id, '?')",current_author.friends], :include => [:authors, :contributions], :page => params[:page], :per_page => 12
        @groups = Group.paginate :page => params[:page], :per_page => 12, :order => 'groups.name'
      else
        @groups = Group.paginate :page => params[:page], :per_page => 12, :order => 'groups.name'
      end
    end
    
    respond_to do |format|
      format.html do 
        if request.xhr?
          render :partial => "index" 
        end
      end
      format.xml  { render :xml => @groups }
      format.json { render :json => @groups, :callback => params[:callback] }
      format.csv  { render :csv => @groups }
    end
  end

  # GET /groups/1
  # GET /groups/1.xml
  def show
    load_group
    @articles = @group.articles.paginate :page => params[:page], :per_page => 20, :include => :retrievals, :order => "retrievals.citations_count desc, articles.year desc"
    
    respond_to do |format|
      format.html do 
        if request.xhr?
          render :partial => params[:partial] 
        else
          
        end
      end
      format.xml do
        response.headers['Content-Disposition'] = 'attachment; filename=' + params[:id].sub(/^info:/,'') + '.xml'
        render :xml => @group.articles.to_xml
      end
      format.csv  { render :csv => @group }
      format.json { render :json => @group.to_json, :callback => params[:callback] }
    end
  end

  # GET /groups/new
  # GET /groups/new.xml
  def new
    @group = Group.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @group }
      format.json { render :json => @group }
    end
  end
  
  # GET /groups/1/edit
  def edit
    @articles = @group.articles.paginate :page => params[:page], :per_page => 20, :include => :retrievals, :order => "retrievals.citations_count desc, articles.year desc"
    if request.xhr?
      render :partial => params[:partial]
    else
      render :show 
    end
  end

  # POST /groups
  # POST /groups.xml
  def create
    # Get group if it exists, otherwise create new one
    #@group = Group.find_or_initialize_by_mas(:mas  => params[:group][:mas])

    #respond_to do |format|
    #  if @group.save
    #    # Fetch group information and update group
    #    properties = Group.fetch_properties(@group)
    #    @group = Group.update_properties(@group, properties)
    #    flash[:notice] = 'Group was successfully created.' if @group.new_record?
    
    #    format.html { redirect_to group_path(@group.mas, :format => :html) }
    #    format.xml  { render :xml => @group, :status => :created, :location => @group }
    #    format.json { render :json => @group, :status => :created, :location => @group }
    #  else
    #    format.html { render :action => "new" }
    #    format.xml  { render :xml => @group.errors, :status => :unprocessable_entity }
    #    format.json { render :json => @group.errors, :status => :unprocessable_entity }
    #  end
    #end
  end

  # PUT /groups/1
  # PUT /groups/1.xml
  def update
    respond_to do |format|
      if @group.update_attributes(params[:group])
        flash[:notice] = 'Group was successfully updated.'
        format.html { render :partial => params[:partial] if request.xhr? }
        format.xml  { head :ok }
        format.json { head :ok }
      else
        format.html { render :partial => params[:partial] if request.xhr? }
        format.xml  { render :xml => @group.errors, :status => :unprocessable_entity }
        format.json { render :json => @group.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /groups/1
  # DELETE /groups/1.xml
  def destroy
    @group.destroy

    respond_to do |format|
      format.html { redirect_to(groups_url) }
      format.xml  { head :ok }
      format.json { head :ok }
    end
  end

protected
  def load_group(options={})
    # Load one group given query params, for the non-#index actions
    # Use :username as :id
    @group = Group.find_by_mendeley!(params[:id], options)
    if @group.nil?
      redirect_to :action => 'index' and return
    end
  end
end