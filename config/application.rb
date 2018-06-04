require 'rails/all'
require 'telegram/bot'
require 'bundler'
# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module TelegramBot
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2
    config.telegram_updates_controller.session_store = :file_store, {expires_in: 1.month}
    config.i18n.default_locale = :ru
    I18n.config.available_locales = :en, :ru
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
  end
end
