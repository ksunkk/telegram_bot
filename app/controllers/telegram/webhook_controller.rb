class Telegram::WebhookController< Telegram::Bot::UpdatesController
  include Telegram::Bot::UpdatesController::MessageContext
  context_to_action!

  def start(*)
    respond_with :message, text: t('.content')
  end
end