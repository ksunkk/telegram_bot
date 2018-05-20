Rails.application.routes.draw do
  telegram_webhook Telegram::WebhookController
end
