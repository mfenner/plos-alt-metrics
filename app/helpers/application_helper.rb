# $HeadURL$
# $Id$
#
# Copyright (c) 2009-2010 by Public Library of Science, a non-profit corporation
# http://www.plos.org/
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

# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def link_to_setup_or_login
    if User.count > 0
      link_to "Login", login_path, :class => current_page?(login_path) ? 'current' : ''
    else
      link_to 'Setup', new_user_path, :class => current_page?(new_user_path) ? 'current' : ''
    end
  end
  
  def active_groups
    @groups = Group.find :all, :conditions => ["sources.active=1"], :include => :sources, :order => :group_id
  end

end
