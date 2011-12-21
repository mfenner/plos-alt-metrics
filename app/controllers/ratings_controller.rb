class RatingsController < ApplicationController
  
  require 'gchart'
  
  # GET /ratings
  # GET /ratings.xml
  def index
    @ratings = Rating.all
    @posts_with_ratings = Post.where('ratings_count > 0')
    @posts = Post.where(:content_type => 'tweet').order(:published_at)
    @posts_with_rts = Post.find(:all, :conditions => "body REGEXP '^RT[[:space:]]'")
    @unique_author_count = Post.count(:author, :distinct => true)
    @unique_article_count = Post.count(:article_title, :distinct => true)
    @unique_journal_count = Post.count(:journal_title, :distinct => true)
    @authors = Author.order('ratings_count desc').limit(5)
    @authors_with_ratings = Author.all
    
    # Create pie chart for rhetoric
    rhetoric = Rating.order('rhetoric').group("rhetoric").count
    @rhetoricchart = Gchart.pie(:data => [rhetoric.map {|a| a[1] }], :size => '330x200', :labels => rhetoric.map {|a| a[0] })
    
    # Create pie chart for posts from author/publisher
    @posts_with_authors = Post.find(:all, :conditions => "ratings.is_author = 1", :include => :ratings) 
    @authorchart = Gchart.pie(:data => [@posts_with_authors.count, @posts_with_ratings.count - @posts_with_authors.count], :size => '330x200', :labels => ["Author", nil])
    
    # Create line chart for using methods/data/conclusions
    @posts_with_method = Post.find(:all, :conditions => "ratings.method = 1", :include => :ratings) 
    @posts_with_data = Post.find(:all, :conditions => "ratings.data = 1", :include => :ratings)
    @posts_with_conclusions = Post.find(:all, :conditions => "ratings.conclusions = 1", :include => :ratings)
    @reusechart = Gchart.bar(:data => [@posts_with_method.count, @posts_with_data.count, @posts_with_conclusions.count], :size => '250x200', :bar_colors => 'ff9900', :bar_width_and_spacing => "70,5", :max_value => @posts_with_ratings.count, :axis_with_labels => 'x',
                :axis_labels => ['Methods|Data|Conclusions'])
    
    # Calculate rating activity by day
    days = Rating.order('created_at').group('DATE(created_at)').count
    @sparkline = Gchart.sparkline(:data => days.map {|a| a[1] }, :size => '200x40', :line_colors => 'ff9900')

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
      if params[:q] == "I'm feeling lucky"
        @posts = Post.paginate :page => params[:page], 
           :per_page => 4,
           :conditions => ["posts.ratings_count IS NULL OR ratings.author_id != ?", author_signed_in? ? current_author.id : 0],
           :include => :ratings,
           :order => 'RAND(DAYOFYEAR(NOW()))'
      else
        @posts = Post.paginate :page => params[:page], 
          :per_page => 20,
          :conditions => ["CONCAT(posts.body,posts.author) REGEXP ?", params[:q]],
          :order => 'posts.published_at desc'
      end
    else
      @posts = Post.where(:content_type => 'tweet').order('posts.published_at desc').paginate(:page => params[:page], :per_page => 20)
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
      if params[:q] == "I'm feeling lucky"
        @posts = Post.paginate :page => params[:page], 
           :per_page => 4,
           :conditions => ["posts.ratings_count IS NULL OR ratings.author_id != ?", author_signed_in? ? current_author.id : 0],
           :include => :ratings,
           :order => 'RAND(DAYOFYEAR(NOW()))'
      else
        @posts = Post.paginate :page => params[:page], 
          :per_page => 20,
          :conditions => ["CONCAT(posts.body,posts.author) REGEXP ?", params[:q]],
          :order => 'posts.published_at desc'
      end
    else
      @posts = Post.where(:content_type => 'tweet').order('posts.published_at desc').paginate(:page => params[:page], :per_page => 20)
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
