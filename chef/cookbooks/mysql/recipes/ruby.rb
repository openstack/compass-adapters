#
# Cookbook Name:: mysql
# Recipe:: ruby
#
# Author:: Jesse Howarth (<him@jessehowarth.com>)
# Author:: Jamie Winsor (<jamie@vialstudios.com>)
#
# Copyright 2008-2013, Opscode, Inc.
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
#

node.set['build_essential']['compiletime'] = true
include_recipe 'build-essential::default'
include_recipe 'mysql::client'

loaded_recipes = if run_context.respond_to?(:loaded_recipes)
                   run_context.loaded_recipes
                 else
                   node.run_state[:seen_recipes]
                 end

if loaded_recipes.include?('mysql::percona_repo')
  case node['platform_family']
  when 'debian'
    resources('apt_repository[percona]').run_action(:add)
  when 'rhel'
    resources('yum_key[RPM-GPG-KEY-percona]').run_action(:add)
    resources('yum_repository[percona]').run_action(:add)
  end
end

node['mysql']['client']['packages'].each do |name|
  resources("package[#{name}]").run_action(:install)
end

save_http_proxy = Chef::Config[:http_proxy]
save_https_proxy = Chef::Config[:https_proxy]
unless node['proxy_url'].nil? or node['proxy_url'].empty?
  Chef::Config[:http_proxy] = "#{node['proxy_url']}"
  Chef::Config[:https_proxy] = "#{node['proxy_url']}"
  ENV['http_proxy'] = "#{node['proxy_url']}"
  ENV['HTTP_PROXY'] = "#{node['proxy_url']}"
  ENV['https_proxy'] = "#{node['proxy_url']}"
  ENV['HTTPS_PROXY'] = "#{node['proxy_url']}"
end

case node['platform_family']
when 'debian'
  chef_gem 'mysql' do
    action :install
    version '2.9.1'
  end
when 'rhel'
  chef_gem 'mysql'
end

Chef::Config[:http_proxy] = save_http_proxy
Chef::Config[:https_proxy] = save_https_proxy
ENV['http_proxy'] = save_http_proxy
ENV['HTTP_PROXY'] = save_http_proxy
ENV['https_proxy'] = save_https_proxy
ENV['HTTPS_PROXY'] = save_https_proxy

