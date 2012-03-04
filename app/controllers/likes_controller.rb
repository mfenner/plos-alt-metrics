class LikesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :load_work
  
  def create
    @like = Like.new(:user_id => current_user.id, :work_id => @work.id)
    @work.likes << @like
    
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
      format.js
    end
  end
  
  def destroy
    @like = Like.find(params[:id])
    @like.destroy
    
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
      format.js
    end
  end
  
protected
  def load_work(options={})
    # Load one work given query params, for the non-#index actions
    @work = Work.find(params[:work_id])
  end
end