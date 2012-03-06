class LikesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :load_work
  
  def create
    @like = Like.new(:user_id => current_user.id, :work_id => @work.id)
    @work.likes << @like
    
    respond_to do |format|
      format.js { render "works/comment" }
    end
  end
  
  def destroy
    @like = Like.find(params[:id])
    @like.destroy
    
    respond_to do |format|
      format.js { render "works/comment" }
    end
  end
  
protected
  def load_work(options={})
    # Load one work given query params, for the non-#index actions
    @work = Work.find(params[:work_id])
  end
end