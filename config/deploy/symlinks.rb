namespace :deploy do
  desc "Make all the symlinks"
  task :symlink, :roles => :app, :except => { :no_release => true } do
    set :normal_symlinks, %w(config/database.yml config/amqp.yml log)

    commands = normal_symlinks.map do |path|
      "rm -rf #{current_path}/#{path} && ln -s #{shared_path}/#{path} #{current_path}/#{path}"
    end

    set :weird_symlinks, {
      "#{shared_path}/bundled_gems" => "vendor/bundle"
    }

    commands += weird_symlinks.map do |from, to|
      "rm -rf #{current_path}/#{to} && ln -s #{from} #{current_path}/#{to}"
    end

    # needed for some of the symlinks
    run "mkdir -p #{current_path}/tmp && mkdir -p #{current_path}/config"
    run "cd #{current_path} && #{commands.join(' && ')}"
  end
end
