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

class UsersController < ApplicationController
  before_filter :authenticate_user!, :except => [ :index, :show ]
  before_filter :load_user, 
                :only => [ :edit, :update, :destroy ]

  # GET /users
  # GET /users.xml
  
  def index
   if !params[:q].blank?
     @works = Work.paginate :page => params[:page], 
       :per_page => 10,
       :include => :users,
       :conditions => ["users.name REGEXP ? or users.username REGEXP ? or users.native_name REGEXP ? or works.title REGEXP ? or works.doi REGEXP ?", params[:q], params[:q], params[:q], params[:q], params[:q]]
   else
     collection = Work
     collection = collection.cited(params[:cited])  if params[:cited]
     collection = collection.query(params[:query])  if params[:query]
     collection = collection.order(params[:order])  if params[:order]
     
     if user_signed_in?
       # Fetch all works by the users you are following
       @works = collection.paginate :conditions => ["FIND_IN_SET(contributors.user_id, '?')",current_user.friends], :include => [:users, :contributors], :page => params[:page], :per_page => 10
     else
       @works = collection.paginate :page => params[:page], :per_page => 10
     end
   end
   
   @source = Source.find_by_type(params[:source]) if params[:source]

   respond_to do |format|
     format.html do 
       if request.xhr?
         render :partial => "index" 
       end
     end
     format.mobile do 
       render :index if request.xhr?
     end
     format.xml  { render :xml => @works }
     format.json { render :json => @works, :callback => params[:callback] }
     format.csv  { render :csv => @works }
     format.rss { render :rss => @works }
     format.js
   end
  end

  # GET /users/1
  # GET /users/1.xml
  def show
    load_user
    
    if params[:refresh] == "now"
      Resque.enqueue(User, @user.id)
    end
        
    respond_to do |format|
      format.html do 
        if request.xhr?
          render :partial => params[:partial] 
        else
          
        end
      end
      format.js { render :show }
      format.mobile
      format.xml do
        response.headers['Content-Disposition'] = 'attachment; filename=' + params[:id].sub(/^info:/,'') + '.xml'
        render :xml => @user.works.to_xml
      end
      format.csv  { render :csv => @user }
      format.json { render :json => @user.to_json, :callback => params[:callback] }
      format.bib { render :bib => @user }
      format.ris { render :ris => @user }
      format.rss { render :rss => @user }
    end
  end

  # GET /users/new
  # GET /users/new.xml
  def new
    @user = User.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @user }
      format.json { render :json => @user }
    end
  end
  
  # GET /users/1/edit
  def edit    
    respond_to do |format|
      format.html { render :show }
      format.js { render :show }
    end
  end

  # POST /users
  # POST /users.xml
  def create
    # Get user if it exists, otherwise create new one
    #@user = User.find_or_initialize_by_mas(:mas  => params[:user][:mas])

    #respond_to do |format|
    #  if @user.save
    #    # Fetch user information and update user
    #    properties = User.fetch_properties(@user)
    #    @user = User.update_properties(@user, properties)
    #    flash[:notice] = 'User was successfully created.' if @user.new_record?
    
    #    format.html { redirect_to user_path(@user.mas, :format => :html) }
    #    format.xml  { render :xml => @user, :status => :created, :location => @user }
    #    format.json { render :json => @user, :status => :created, :location => @user }
    #  else
    #    format.html { render :action => "new" }
    #    format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
    #    format.json { render :json => @user.errors, :status => :unprocessable_entity }
    #  end
    #end
  end

  # PUT /users/1
  # PUT /users/1.xml
  def update  
    respond_to do |format|
      if @user.update_attributes(params[:user])
        if params[:service] == "mas"
          # First remove all mas work claims, e.g. because Microsoft Academic Search ID was changed or set to empty 
          @user.contributors.where(:service => "mas").each do |contributor|
            contributor.update_attributes(:user_id => nil)
          end
          
          # Fetch works from user, return nil if no response
          results = User.fetch_works_from_mas(@user)
          
          unless results.empty?
            results.each do |result|
              # Only add works with DOI and title
              unless result["DOI"].nil? or result["Title"].nil?
                #result["DOI"] = DOI::clean(result["DOI"])
                work = Work.find_or_create_by_doi(:doi => result["DOI"], :title => result["Title"])
                work.save
                # Check that DOI is valid
                if work.valid?
                  work.update_attributes(:mas => result["ID"])
                  result["Author"].each do |user|
                    contributor = Contributor.find_or_create_by_work_id_and_mas_and_service(:work_id => work.id,
                                                            :mas => user["ID"],
                                                            :service => "mas",
                                                            :surname => user["LastName"],
                                                            :given_name => user["FirstName"]) 
                    contributor.update_attributes(:user_id => @user.id) if (user["ID"].to_s == @user.mas)
                  end
                  Resque.enqueue(Work, work.id)
                end
              end
            end
          end
        elsif params[:service] == "userclaim"
          # First remove all userclaim work claims, e.g. because AuthorClaim ID was changed or set to empty
          @user.contributors.where(:service => "userclaim").each do |contributor|
            contributor.update_attributes(:user_id => nil)
          end
          
          # Fetch works from user, return nil if no response
          results = User.fetch_works_from_userclaim(@user)
          
          unless results.blank?
            results[:works].each do |result|
              # Only add works with DOI and title
              unless result["DOI"].nil? or result["Title"].nil?
                #result["DOI"] = DOI::clean(result["DOI"])
                work = Work.find_or_create_by_doi(:doi => result["DOI"], :title => result["Title"])
                work.save
                # Check that DOI is valid
                if work.valid?
                  contributor = Contributor.create(:work_id => work.id,
                                                          :user_id => @user.id,
                                                          :surname => results[:contributor]["surname"],
                                                          :given_name => results[:contributor]["given_name"],
                                                          :service => "userclaim",
                                                          :userclaim => @user.userclaim)
                end
                Resque.enqueue(Work, work.id)
              end
            end
          end
        elsif params[:service] == "scopus"
          # First remove all scopus work claims, e.g. because Scopus Author ID was changed or set to empty 
          @user.contributors.where(:service => "scopus").each do |contributor|
            contributor.update_attributes(:user_id => nil)
          end

          # Fetch works from user, return nil if no response
          results = User.fetch_works_from_scopus(@user)

          unless results.empty?
            results.each do |result|
              # Only add works with DOI and title
              unless result["DOI"].nil? or result["Title"].nil?
                #result["DOI"] = DOI::clean(result["DOI"])
                work = Work.find_or_create_by_doi(:doi => result["DOI"], :title => result["Title"])
                work.save
                # Check that DOI is valid
                if work.valid?
                  work.update_attributes(:scopus => result["ID"])
                  result["Author"].each do |user|
                    contributor = Contributor.find_or_create_by_work_id_and_scopus_and_service(:work_id => work.id,
                                                            :scopus => user["ID"],
                                                            :service => "scopus",
                                                            :surname => user["LastName"],
                                                            :given_name => user["FirstName"]) 
                    contributor.update_attributes(:user_id => @user.id) if (user["ID"].to_s == @user.mas)
                  end
                  Resque.enqueue(Work, work.id)
                end
              end
            end
          end
        elsif params[:service] == "twitter"
          Resque.enqueue(Service, @user.id)
        end
        format.html { render :show }
        format.js { render :show }
        format.xml  { head :ok }
        format.json { head :ok }
      else  
        format.js { render :show }
        format.html { render :partial => params[:partial] if request.xhr? }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
        format.json { render :json => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.xml
  def destroy
    @user.destroy

    respond_to do |format|
      format.html { redirect_to(users_url) }
      format.xml  { head :ok }
      format.json { head :ok }
    end
  end

protected
  def load_user(options={})
    # Load one user given query params, for the non-#index actions
    # Use :username as :id
    @user = User.find_by_username!(params[:id], options)
    if @user.nil?
      redirect_to :action => 'index' and return
    end
  end
end