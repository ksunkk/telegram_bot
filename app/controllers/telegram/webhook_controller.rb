class Telegram::WebhookController < Telegram::Bot::UpdatesController
  include Telegram::Bot::UpdatesController::MessageContext
  context_to_action!

  def start(*)
    save_context :login
    respond_with :message, text: 'Выберите язык:', reply_markup: {
      inline_keyboard: [
        [
          { text: 'Русский', callback_data: 'ru' },
          { text: 'English', callback_data: 'en' },
        ],
      ],
    }
  end

  def login(data, *)
    save_context :login
    if data.match?('^\+79\d{9}')
      user = User.where(phone: data).first
      if user
        save_context :user_board
        reply_txt = "Здравствуй, #{user.name}"
        reply_keyboard = {
          inline_keyboard: [
            OptionsService.list_for(user)
          ]
        }
      else
        save_context :login
        reply_txt = "Пользователь с таким номером не найден, обратитесь к администратору"
        reply_keyboard = {}
      end
    else
      save_context :login
      reply_txt = "Некорректно введён номер"
      reply_keyboard = {}
    end
    respond_with :message, text: reply_txt, reply_markup: reply_keyboard
  end

  def user_board(*)
  end

  def callback_query(data)
    answer_data, answer_params = CallbackService.process(data)
    respond_with :message, text: answer_data
  end

  def message(message)
    respond_with :message, text: t('.content', text: message['text'])
  end
end