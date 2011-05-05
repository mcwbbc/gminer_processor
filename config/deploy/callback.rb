namespace :deploy do

  desc "expand the gems"
  task :gems, :except => { :no_release => true } do
    run "cd #{current_path}; bundle install --gemfile Gemfile --deployment --without test cucumber"
  end

end
