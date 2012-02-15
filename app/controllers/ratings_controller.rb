class RatingsController < ApplicationController
  
  # GET /ratings
  # GET /ratings.xml
  def index
    @ratings = Rating.all
    @posts_with_ratings = Post.where('ratings_count > 0')
    @posts = Post.where(:content_type => 'tweet').order(:published_at)
    @posts_with_rts = Post.find(:all, :conditions => "body REGEXP '^RT[[:space:]]'")
    @posts_with_spam = Post.find(:all, :conditions => "ratings.spam = 1", :include => :ratings)
    @posts_with_topic = Post.joins(:ratings).where("ratings.topic IS NOT NULL")
    @posts_with_title = Post.find(:all, :conditions => "body REGEXP IF(LENGTH(article_title) < 20, article_title, LEFT(article_title, 20))")
    @unique_author_count = Post.count(:author, :distinct => true)
    @unique_article_count = Post.count(:article_title, :distinct => true)
    @unique_journal_count = Post.count(:journal_title, :distinct => true)
    @authors = Author.order('ratings_count desc').limit(10)
    @authors_with_ratings = Author.all
    
    # Create pie chart for subject area
    topic_names = ["Medicine & Health", "Life Sciences", "Physics & Astronomy", "Chemistry & Materials Science", "Earth Sciences", "Social Sciences & Economics", "Computer Science & Math", "Other"]
    topics = []
    topic_names.each_with_index do |item, index|
      topics << Post.joins(:ratings).where(:ratings => { :topic => item })
    end
    
    @topicchart = LazyHighCharts::HighChart.new('pie') do |f|
      f.chart({ :defaultSeriesType=>"pie", :marginLeft => 70, :marginRight => 70, :backgroundColor => nil } )
      f.series(:name => "Tweets", :data => [{ :name => topic_names[0], :y => topics[0].count, :color => "#F7FCF5" }, 
                                            { :name => topic_names[1], :y => topics[1].count, :color => "#E5F5E0"}, 
                                            { :name => topic_names[2], :y => topics[2].count, :color => "#C7E9C0"},
                                            { :name => topic_names[3], :y => topics[3].count, :color => "#A1D99B"},
                                            { :name => topic_names[4], :y => topics[4].count, :color => "#74C476"},
                                            { :name => topic_names[5], :y => topics[5].count, :color => "#41AB5D"},
                                            { :name => topic_names[6], :y => topics[6].count, :color => "#238B45"},
                                            { :name => topic_names[7], :y => topics[7].count, :color => "#006D2C"}])
      f.options[:title][:text] = nil
    end
    
    # Create pie chart for rhetoric
    rhetoric = Rating.order('rhetoric').group("rhetoric").count
    @posts_with_agreement = Post.find(:all, :conditions => "ratings.rhetoric = 'agreesWith'", :include => :ratings)
    @posts_with_disagreement = Post.find(:all, :conditions => "ratings.rhetoric = 'disagreesWith'", :include => :ratings)
    @rhetoricchart = LazyHighCharts::HighChart.new('pie') do |f|
      f.chart({ :defaultSeriesType=>"pie", :marginLeft => 70, :marginRight => 70, :backgroundColor => nil } )
      f.series(:name => "Tweets", :data => [{ :name => "agrees with", :y => @posts_with_agreement.count, :color => "#41AB5D" }, { :name => "disagrees with", :y => @posts_with_disagreement.count, :color => "#A1D99B"}, { :name => "discusses", :y => @posts_with_ratings.count - (@posts_with_agreement.count + @posts_with_disagreement.count), :color => "#F7FCF5"} ])
      f.options[:title][:text] = nil
    end
    
    # Create pie chart for posts from author/publisher
    @posts_with_authors = Post.find(:all, :conditions => "ratings.is_author = 1", :include => :ratings) 
    @authorchart = LazyHighCharts::HighChart.new('pie') do |f|
      f.chart({:defaultSeriesType=>"pie", :marginLeft => 70, :marginRight => 70, :backgroundColor => nil } )
      f.series(:name => "Tweets", :data => [{ :name => "Author/Publisher", :y => @posts_with_authors.count, :color => "#41AB5D" }, { :name => "Other", :y => @posts_with_ratings.count - @posts_with_authors.count, :color => "#F7FCF5" }])
      f.options[:title][:text] = nil
    end
    
    # Create bar chart for using methods/data/conclusions
    @posts_with_method = Post.find(:all, :conditions => "ratings.method = 1", :include => :ratings) 
    @posts_with_data = Post.find(:all, :conditions => "ratings.data = 1", :include => :ratings)
    @posts_with_conclusions = Post.find(:all, :conditions => "ratings.conclusions = 1", :include => :ratings)
    @reusechart = LazyHighCharts::HighChart.new('chart') do |f|
      f.chart({:defaultSeriesType=>"column", :height => 250, :backgroundColor => nil } )
      f.series(:name => "Tweets", :color => "#41AB5D", :data => [@posts_with_method.count, @posts_with_data.count, @posts_with_conclusions.count], :colors => ["#41AB5D", "#A1D99B", "#F7FCF5"])
      f.options[:xAxis] = { :categories => ['Methods', 'Data', 'Conclusions'], :tickLength => 0, :lineColor => "#000000" }
      f.options[:yAxis] = { :max => @posts_with_ratings.count, :lineWidth => 1, :lineColor => "#000000", :gridLineWidth => 0, :title => nil, :labels  => { :enabled => true }, :tickInterval => @posts_with_ratings.count, :showFirstLabel => false }
      f.options[:title][:text] = nil
      f.options[:plotOptions] = { :column => { :borderWidth => 0 } }
      f.options[:legend] = false
    end 
    
    # Calculate rating activity by day
    days = Rating.order('created_at').group('DATE(created_at)').count
    @activitychart = LazyHighCharts::HighChart.new('chart') do |f|
      f.chart({:defaultSeriesType=>"spline", :height => 150, :marginRight => 30, :backgroundColor => nil } )
      f.series(:name => "Ratings", :color => "#41AB5D", :data => days.map {|a| [Date.strptime(a[0], '%Y-%m-%d').to_time.utc.to_i * 1000, a[1]] })
      f.options[:xAxis] = { :type => 'datetime', :tickLength => 0, :lineColor => "#000000", :labels  => { :enabled => true } }
      f.options[:yAxis] = { :min => 0, :max => @posts_with_ratings.count, :lineWidth => 1, :lineColor => "#000000", :gridLineWidth => 0, :title => nil, :labels  => { :enabled => true }, :tickInterval => @posts_with_ratings.count, :showFirstLabel => false }
      f.options[:title][:text] = nil
      f.options[:legend] = false
      f.options[:plotOptions] = { :column => { :connectNulls => true } }
    end
      
    respond_to do |format|
      format.html # index.html.erb
      format.mobile # index.mobile.erb
      format.json # index.mobile.erb
      format.csv # index.mobile.erb
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
    @post = Post.find(params[:post_id])
    @rating = Rating.find_or_initialize_by_id(params[:id], :rhetoric => "discusses") 

    respond_to do |format|
      format.html
      format.mobile # new.mobile.erb
    end
  end

  # GET /ratings/1/edit
  def edit
    @rating = Rating.find(params[:id])
  end

  # POST /ratings
  # POST /ratings.xml
  def create
    if params[:format] == "mobile"
      # Workaround because we have to use check_box_tag
      params[:rating][:spam] = params[:rating][:spam] || 0
      params[:rating][:is_author] = params[:rating][:is_author] || 0
      params[:rating][:method] = params[:rating][:method] || 0
      params[:rating][:data] = params[:rating][:data] || 0
      params[:rating][:conclusions] = params[:rating][:conclusions] || 0
    end
    
    @post = Post.find(params[:rating][:post_id])
    @rating = Rating.new(params[:rating])
    @rating.save
    
    if !params[:q].blank?
      if params[:q] == "I'm feeling lucky"
        @posts = Post.paginate :page => params[:page], 
           :per_page => 4,
           :conditions => ["posts.ratings_count IS NULL OR posts.id NOT IN (SELECT post_id FROM ratings WHERE author_id = ?)", author_signed_in? ? current_author.id : 0],
           :include => :ratings,
           :order => 'RAND(DAYOFYEAR(NOW()))'
      else
        @posts = Post.paginate :page => params[:page], 
          :per_page => 25,
          :conditions => ["CONCAT(posts.body,posts.author) REGEXP ?", params[:q]],
          :order => 'RAND(DAYOFYEAR(NOW()))'
      end
    elsif params[:format] == "mobile"
      @posts = Post.find(:all, :conditions => ["posts.ratings_count IS NULL OR posts.id NOT IN (SELECT post_id FROM ratings WHERE author_id = ?)", author_signed_in? ? current_author.id : 0], :include => :ratings, :order => 'RAND(DAYOFYEAR(NOW()))', :limit => 10)
    else
      @posts = Post.where(:content_type => 'tweet').order('RAND(DAYOFYEAR(NOW()))').paginate(:page => params[:page], :per_page => 25)
    end
    
    respond_to do |format|
      format.js { render "posts/index" }
      format.html { render "posts/index"}
      format.mobile { render "posts/index"}
    end
  end

  # PUT /ratings/1
  # PUT /ratings/1.xml
  def update
    unless params[:q].blank?
      if params[:q] == "I'm feeling lucky"
        @posts = Post.paginate :page => params[:page], 
           :per_page => 4,
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
    @rating = Rating.find(params[:id])
    @post = @rating.post
    @rating.update_attributes(params[:rating])
    
    respond_to do |format|
      format.js { render "posts/index" }
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
  
  def update_spam
    @is_spam = params[:spam].to_i == 1 ? true : false
  end
end
