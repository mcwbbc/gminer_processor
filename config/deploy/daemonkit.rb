# =========================================================================
# These are the tasks that are available to help with deploying web apps,
# and specifically, Rails applications. You can have cap give you a summary
# of them with `cap -T'.
# =========================================================================

namespace :deploy do

  desc <<-DESC
    Restarts your application. This works by calling 'stop' task, \
    followed by the 'start' task.

    See the descriptions for the 'start' and 'stop' tasks for any \
    additional info.
  DESC
  task :restart, :except => { :no_release => true } do
    stop
    start
  end

  desc <<-DESC
    Start the daemon processes. This will attempt to invoke a script \
    in your application called `bin/:application', with the 'start' parameter.

    By default, the script will be executed via sudo as the `app' user. If \
    you wish to run it as a different user, set the :runner variable to \
    that user. If you are in an environment where you can't use sudo, set \
    the :use_sudo variable to false.
  DESC
  task :start do
    try_runner "cd #{current_path} && /usr/bin/env DAEMON_ENV=#{fetch(:daemon_env)} #{current_path}/bin/#{application} start"
  end

  desc <<-DESC
    Stop the daemon processes. This will call 'bin/:application stop'.

    By default, the script will be executed via sudo as the `app' user. If \
    you wish to run it as a different user, set the :runner variable to \
    that user. If you are in an environment where you can't use sudo, set \
    the :use_sudo variable to false.
  DESC
  task :stop do
    try_runner "cd #{current_path} && /usr/bin/env DAEMON_ENV=#{fetch(:daemon_env)} #{current_path}/bin/#{application} stop"
  end

end
