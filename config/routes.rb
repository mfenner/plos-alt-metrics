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

PlosAltMetrics::Application.routes.draw do
  devise_for :authors, :controllers => { :omniauth_callbacks => "authors/omniauth_callbacks" } do
    get '/authors/auth/:provider' => 'authors/omniauth_callbacks#passthru'
    get 'sign_in', :to => 'authors/sessions#new', :as => :new_author_session
    delete 'sign_out', :to => 'authors/sessions#destroy', :as => :destroy_author_session
  end
  devise_for :authors do
    get "/sign_out" => "devise/sessions#destroy"
  end
  
  # Wildcard match for DOI
  #get '/articles/*doi' => 'articles#show'
  resources :articles, :requirements => { :id => /.+?/ }
  match "/group/articles(/:id)(.:format)" => "groups#groupArticleSummaries"
  
  # Admin resources
  resources :sources
  resources :groups
  resources :authentications
  get '/docs(/:action)', :controller => :docs, :format => false
  get 'about', :to => 'index#index', :as => "about"
  
  # Authors are in default path, should therefore be defined after admin resources. 
  # Root goes to authors#index, needs to be defined.
  resources :authors, :path => "/"
  root :to => "authors#index"

end