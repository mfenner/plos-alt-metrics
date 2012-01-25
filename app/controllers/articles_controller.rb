class ArticlesController < ApplicationController
  
  def index
    redirect_to works_path
  end

  def show
    @work = Work.find_by_short_doi!(params[:id])
    redirect_to works_path(@work)
  end
end