class CommentsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :load_work

  def index
    respond_to do |format|
      format.js { render "works/work" }
    end
  end
  
  def new
    @comment = Comment.new
    
    respond_to do |format|
      format.js { render "works/work" }
    end
  end
  
  def create
    @comment = Comment.new(params[:comment])
    @work.comments << @comment unless @comment.text.blank?
    
    respond_to do |format|
      format.js { render "works/work" }
    end
  end
  
  def edit
    @comment = Comment.find(params[:id])
    
    respond_to do |format|
      format.js { render "works/work" }
    end
  end
  
  def update
    @comment = Comment.find(params[:id])
    @comment.update_attributes(params[:comment])
    @comment.destroy if @comment.text.blank?
    
    respond_to do |format|
      format.js { render "works/work" }
    end
  end

  def destroy
    @comment = Comment.find(params[:id])
    @comment.destroy
    
    respond_to do |format|
      format.js { render "works/work" }
    end  
  end

protected
  def load_work(options={})
    # Load one work given query params, for the non-#index actions
    @work = Work.find(params[:work_id])
  end
end