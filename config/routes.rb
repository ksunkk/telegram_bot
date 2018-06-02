Rails.application.routes.draw do
  telegram_webhook Telegram::WebhookController
  get 'test', to: 'test#index'
end
