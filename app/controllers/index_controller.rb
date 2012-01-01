class IndexController < ApplicationController
  
  def index
    respond_to do |format|
      format.html # index.html.haml
      format.mobile # index.mobile.erb
    end
  end
  
end