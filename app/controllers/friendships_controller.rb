# Copyright (c) 2011 Martin Fenner
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

class FriendshipsController < ApplicationController
  def create  
    @friendship = current_author.friendships.build(:friend_id => params[:friend_id])  
    if @friendship.save  
      flash[:notice] = "Added friend."  
      redirect_to root_url  
    else  
      flash[:error] = "Error occurred when adding friend."  
      redirect_to root_url  
    end  
  end  

  def destroy  
    @friendship = current_author.friendships.find(params[:id])  
    @friendship.destroy  
    flash[:notice] = "Successfully destroyed friendship."  
    redirect_to root_url  
  end
end
