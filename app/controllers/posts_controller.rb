class PostsController < ApplicationController
  # GET /posts
  # GET /posts.xml
  def index
    if params[:format] == "mobile"
      @posts = Post.find(:all, :conditions => ["posts.ratings_count IS NULL OR posts.id NOT IN (SELECT post_id FROM ratings WHERE author_id = ?)", author_signed_in? ? current_author.id : 0], :include => :ratings, :order => 'RAND(DAYOFYEAR(NOW()))', :limit => 10)
    elsif !params[:q].blank?
      if params[:q] == "I'm feeling lucky"
         @posts = Post.paginate :page => params[:page], 
           :per_page => 5,
           :conditions => ["posts.ratings_count IS NULL OR posts.id NOT IN (SELECT post_id FROM ratings WHERE author_id = ?)", author_signed_in? ? current_author.id : 0],
           :include => :ratings,
           :order => 'RAND(DAYOFYEAR(NOW()))'
      else
        @posts = Post.paginate :page => params[:page], 
          :per_page => 25,
          :conditions => ["CONCAT(posts.body,posts.author) REGEXP ?", params[:q]],
          :order => 'RAND(DAYOFYEAR(NOW()))'
      end
    else
      @posts = Post.where(:content_type => 'tweet').order('RAND(DAYOFYEAR(NOW()))').paginate(:page => params[:page], :per_page => 25)
    end

    respond_to do |format|
      format.html { render }
      format.mobile # index.mobile.erb
      format.js
      format.xml  { render :xml => @posts }
      format.csv # index.csv.erb
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
        if params[:q] == "I'm feeling lucky"
           @posts = Post.paginate :page => params[:page], 
             :per_page => 5,
             :conditions => ["posts.ratings_count IS NULL OR posts.id NOT IN (SELECT post_id FROM ratings WHERE author_id = ?)", author_signed_in? ? current_author.id : 0],
             :include => :ratings,
             :order => 'RAND(DAYOFYEAR(NOW()))'
        else
          @posts = Post.paginate :page => params[:page], 
            :per_page => 25,
            :conditions => ["CONCAT(posts.body,posts.author) REGEXP ?", params[:q]],
            :order => 'RAND(DAYOFYEAR(NOW()))'
        end
      else
        @posts = Post.where(:content_type => 'tweet').order('RAND(DAYOFYEAR(NOW()))').paginate(:page => params[:page], :per_page => 25)
      end
    
    @post = Post.find(params[:id])
    @rating = Rating.find_by_post_id_and_author_id(params[:id], params[:author_id])
    
    if @rating.nil?
      @rating = Rating.new(:rhetoric => "discusses") 
    end
    
    respond_to do |format|
      format.html
      format.mobile # edit.mobile.erb
      format.js { render "posts/index" }
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
    
    @rating = Rating.find_by_post_id_and_author_id(params[:id], params[:author_id])
    if @rating.nil?
      @rating = Rating.new(params[:rating])
      @rating.save
    else
      @rating.update_attributes(params[:rating])
    end
    
    unless params[:q].blank?
      if params[:q] == "I'm feeling lucky"
         @posts = Post.paginate :page => params[:page], 
           :per_page => 5,
           :conditions => ["posts.ratings_count IS NULL OR posts.id NOT IN (SELECT post_id FROM ratings WHERE author_id = ?)", author_signed_in? ? current_author.id : 0],
           :include => :ratings,
           :order => 'RAND(DAYOFYEAR(NOW()))'
      else
        @posts = Post.paginate :page => params[:page], 
          :per_page => 25,
          :conditions => ["CONCAT(posts.body,posts.author) REGEXP ?", params[:q]],
          :order => 'RAND(DAYOFYEAR(NOW()))'
      end
    else
      @posts = Post.where(:content_type => 'tweet').order('RAND(DAYOFYEAR(NOW()))').paginate(:page => params[:page], :per_page => 25)
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
