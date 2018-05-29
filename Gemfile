source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.4.1'

gem 'rails', '~> 5.2.0'
gem 'pg', '>= 0.18', '< 2.0'
gem 'puma', '~> 3.11'

gem 'telegram-bot'
gem 'telegram-bot-types'
gem 'carrierwave-postgresql'
gem 'certified', '~> 1.0'
gem 'http'
group :development do
  gem 'pry'
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem "capistrano"
end

group :test do
  gem 'capybara', '>= 2.15', '< 4.0'
  gem 'rspec'
end
