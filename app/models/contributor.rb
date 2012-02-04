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

class Contributor < ActiveRecord::Base
  belongs_to :work
  belongs_to :journal_article, :foreign_key => :work_id
  belongs_to :conference_paper, :foreign_key => :work_id
  belongs_to :book_content, :foreign_key => :work_id
  belongs_to :user
  acts_as_list :scope => :work
  
  attr_accessible :work_id, :user_id, :service, :mas, :authorclaim, :surname, :given_name, :role
  
  def name
    return surname if given_name.blank?
    # Add periods if given name is abbreviated, i.e. consists only of capital letters
    abbr = given_name.scan(/[A-Z]/)
    if abbr.length == given_name.length
      surname + ", " + abbr.join(".") + "."
    else
      surname + ", " + given_name
    end
  end
  
  def brief_name
    return surname if given_name.blank?
    abbr = given_name.scan(/[A-Z]/)
    if abbr.length == given_name.length
      surname + " " + given_name
    else
      surname + " " + given_name[0..0]
    end
  end
end