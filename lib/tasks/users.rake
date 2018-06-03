namespace :users do
  desc 'Добавляем новых юзеров из конфига'
  task add_from_config: :environment do
    users = Yaml.load_file('config/users.yml')
    users.each { |params| User.create(params) if User.where(phone: params['phone']).blank? }
  end
end
