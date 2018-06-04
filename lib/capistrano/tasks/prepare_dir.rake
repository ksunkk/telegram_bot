namespace :deploy do
  task :prepare_dir do
  	execute "rvm use ruby-2.4.1"
  	execute "bundle install"
  end
end
after 'deploy:finished', 'deploy:prepare_dir'