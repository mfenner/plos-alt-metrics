# $HeadURL: http://ambraproject.org/svn/plos/alm/head/config/initializers/01_load_config.rb $
# $Id: 01_load_config.rb 5693 2010-12-03 19:09:53Z josowski $
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

APP_CONFIG = YAML.load_file("#{Rails.root}/config/settings.yml")[Rails.env]

REST_AUTH_SITE_KEY = APP_CONFIG['rest_auth_site_key']
REST_AUTH_DIGEST_STRETCHES = APP_CONFIG['rest_auth_digest_stretches']
