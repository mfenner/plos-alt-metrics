class ArticlesController < ApplicationController
  
  def index
    redirect_to users_path
  end

  def show
    @work = Work.find_by_short_doi!(params[:id])
    redirect_to work_path(@work.id)
  end
end