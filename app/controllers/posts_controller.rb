class PostsController < ApplicationController
  # GET /posts
  # GET /posts.xml
  def index
    unless params[:q].blank?
      @posts = Post.paginate :page => params[:page], 
        :per_page => 20,
        :conditions => ["posts.content_type = 'tweet' AND CONCAT(posts.body,posts.author) REGEXP ?", params[:q]],
        :order => 'posts.original_id' 
    else
      @posts = Post.where(:content_type => 'tweet').paginate(:page => params[:page], :per_page => 20)
    end

    respond_to do |format|
      format.html do 
        if request.xhr?
          render :partial => "index" 
        end
      end
      format.xml  { render :xml => @posts }
    end
  end

  # GET /posts/1
  # GET /posts/1.xml
  def show
    @post = Post.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @post }
    end
  end

  # GET /posts/new
  # GET /posts/new.xml
  def new
    @post = Post.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @post }
    end
  end

  # GET /posts/1/edit
  def edit
    unless params[:q].blank?
      @posts = Post.paginate :page => params[:page], 
        :per_page => 10,
        :conditions => ["posts.content_type = 'tweet' AND CONCAT(posts.body,posts.author) REGEXP ?", params[:q]],
        :order => 'posts.original_id' 
    else
      @posts = Post.paginate :page => params[:page], :per_page => 20, :conditions => ["posts.content_type = 'tweet'"]
    end
    
    @post = Post.find(params[:id])
    @rating = Rating.find_by_post_id_and_author_id(params[:id], params[:author_id])
    
    if @rating.nil?
      if @post.body.match(/^RT/)
        @rating = Rating.new(:rhetoric => "agreesWith") 
      else
        @rating = Rating.new(:rhetoric => "discusses") 
      end
    end
    
    if request.xhr?
      render :partial => "index" 
    end
  end

  # POST /posts
  # POST /posts.xml
  def create
    @post = Post.new(params[:post])

    respond_to do |format|
      if @post.save
        format.html { redirect_to(@post, :notice => 'Post was successfully created.') }
        format.xml  { render :xml => @post, :status => :created, :location => @post }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @post.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /posts/1
  # PUT /posts/1.xml
  def update
    @post = Post.find(params[:id])
    
    unless params[:q].blank?
      @posts = Post.paginate :page => params[:page], 
        :per_page => 10,
        :conditions => ["posts.content_type = 'tweet' AND CONCAT(posts.body,posts.author) REGEXP ?", params[:q]],
        :order => 'posts.original_id' 
    else
      @posts = Post.paginate :page => params[:page], :per_page => 10, :conditions => ["posts.content_type = 'tweet'"]
    end
    
    @rating = Rating.find_by_post_id_and_author_id(params[:id], params[:author_id])
    if @rating.nil?
      @rating = Rating.new(params[:rating])
      @rating.save
    else
      @rating.update_attributes(params[:rating])
    end
    
    respond_to do |format|
      format.html { render :partial => 'index' }
    end
  end

  # DELETE /posts/1
  # DELETE /posts/1.xml
  def destroy
    @post = Post.find(params[:id])
    @post.destroy

    respond_to do |format|
      format.html { redirect_to(posts_url) }
      format.xml  { head :ok }
    end
  end
end
