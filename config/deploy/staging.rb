#############################################################
#	Application
#############################################################

set :daemon_env, 'staging'
set :deploy_to, "/www/daemons/staging/#{application}"
set :host, "stagingserver"
server host, :app
