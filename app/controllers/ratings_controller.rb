class RatingsController < ApplicationController
  
  require 'gchart'
  
  # GET /ratings
  # GET /ratings.xml
  def index
    @ratings = Rating.all
    @posts = Post.where('ratings_count > 0')
    @all_posts = Post.where(:content_type => 'tweet')
    @authors = Author.order('ratings_count desc').limit(3)
    
    @days = Rating.order('created_at asc').group('DATE(created_at)').count
    data = [0]
    @days.each do |day|
      data << day[1]
    end
    @sparkline = Gchart.sparkline(:data => data, :size => '120x40', :line_colors => '0077CC')

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /ratings/1
  # GET /ratings/1.xml
  def show
    @rating = Rating.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @rating }
    end
  end

  # GET /ratings/new
  # GET /ratings/new.xml
  def new
    @rating = Rating.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @rating }
    end
  end

  # GET /ratings/1/edit
  def edit
    @rating = Rating.find(params[:id])
  end

  # POST /ratings
  # POST /ratings.xml
  def create
    unless params[:q].blank?
      @posts = Post.paginate :page => params[:page], 
        :per_page => 10,
        :conditions => ["posts.content_type = 'tweet' AND CONCAT(posts.body,posts.author) REGEXP ?", params[:q]],
        :order => 'posts.original_id' 
    else
      @posts = Post.where(:content_type => 'tweet').paginate(:page => params[:page], :per_page => 20)
    end
    @post = Post.find(params[:rating][:post_id])
    
    @rating = Rating.new(params[:rating])
    @rating.save
    
    respond_to do |format|
      format.html { render :partial => 'posts/index' }
    end
  end

  # PUT /ratings/1
  # PUT /ratings/1.xml
  def update
    unless params[:q].blank?
      @posts = Post.paginate :page => params[:page], 
        :per_page => 10,
        :conditions => ["posts.content_type = 'tweet' AND CONCAT(posts.body,posts.author) REGEXP ?", params[:q]],
        :order => 'posts.original_id' 
    else
      @posts = Post.where(:content_type => 'tweet').paginate(:page => params[:page], :per_page => 20)
    end
    @rating = Rating.find(params[:id])
    @post = @rating.post
    @rating.update_attributes(params[:rating])
    
    respond_to do |format|
      format.html { render :partial => 'posts/index' }
    end
  end

  # DELETE /ratings/1
  # DELETE /ratings/1.xml
  def destroy
    @rating = Rating.find(params[:id])
    @rating.destroy

    respond_to do |format|
      format.html { redirect_to(ratings_url) }
      format.xml  { head :ok }
    end
  end
end
