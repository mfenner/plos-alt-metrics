class RatingsController < ApplicationController
  # GET /ratings
  # GET /ratings.xml
  def index
    @ratings = Rating.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @ratings }
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
        :conditions => ["posts.content_type = 'tweet' AND posts.body REGEXP ?", params[:q]],
        :order => 'posts.original_id' 
    else
      @posts = Post.where(:content_type => 'tweet').paginate(:page => params[:page], :per_page => 10)
    end
    @post = Post.find(params[:rating][:post_id])
    
    @rating = Rating.new(params[:rating])
    @rating.save
    
    respond_to do |format|
      format.html { render 'posts/index' }
    end
  end

  # PUT /ratings/1
  # PUT /ratings/1.xml
  def update
    unless params[:q].blank?
      @posts = Post.paginate :page => params[:page], 
        :per_page => 10,
        :conditions => ["posts.content_type = 'tweet' AND posts.body REGEXP ?", params[:q]],
        :order => 'posts.original_id' 
    else
      @posts = Post.where(:content_type => 'tweet').paginate(:page => params[:page], :per_page => 10)
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
