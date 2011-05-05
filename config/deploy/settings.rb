#############################################################
#  Application
#############################################################

set :application, 'gminer_processor'

#############################################################
#  Git
#############################################################

set :scm, :git
set :repository,  "git@github.com:mcwbbc/#{application}.git"
set :branch, 'master'

#############################################################
#  Users
#############################################################

set :user, "user"

#############################################################
#  Server
#############################################################

set :daemon_env, 'processing'
set :deploy_to, "/www/daemons/processing/#{application}"
set :host, "server"
server host, :app

#############################################################
#  Settings
#############################################################

default_run_options[:pty] = true
set :use_sudo, false

#############################################################
#  Post Deploy Hooks
#############################################################

after "deploy:update_code", "deploy:write_revision"
before "deploy:gems", "deploy:symlink"
after "deploy:update_code", "deploy:gems"
