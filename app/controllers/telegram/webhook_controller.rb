class Telegram::WebhookController < Telegram::Bot::UpdatesController
  include Telegram::Bot::UpdatesController::MessageContext
  context_to_action!
  use_session!

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
        unless user.telegram_id
          user.update_attributes(telegram_id: from['id'])
        end
        reply_txt = "Здравствуй, #{user.name}"
        reply_keyboard = {
          inline_keyboard: [
            OptionsService.list_for(user)
          ]
        }
      else
        # TODO: экшн для связи с администратором
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
    respond_with :message, text: 'Выберите действие:', reply_markup: {
      inline_keyboard: [
        OptionsService.list_for(current_user)
      ]
    }
  end

  def csv_db
    unless current_user(from).has_role? :admin
      save_context :user_board
      respond_with :message, text: "Недостаточно прав"
    end
    csv_data = CsvService.full_db
    reply_with :file, csv_data.force_encoding('UTF-8'),
                      :type => 'text/csv; charset=UTF-8; header=present',
                      :disposition => "attachment;"
  end

  # TODO: уточнить как быть в случае пришло уведомление что ВЕРИФИЦИРУЙ -> а это уже верифицировали -> што делать
  # И каким образом дополняются поля
  def verify_org
    unless current_user(from).has_role? :verificator
      save_context :user_board
      respond_with :message, text: "Недостаточно прав"
    end
  end

  # TODO: а тут как, просто сумма или каждый пользователь, или вводить номер нужного
  def stats
    if current_user(from).has_role? :admin
    else
      stat = current_user(from).statistic
      respond_with :meassage, text: "верифицировано: #{stat.valid_count},\nНеверифицировано: #{stat.valid_count}"
    end
  end

  def new_org_info
    unless current_user(from).has_role? :fieldworker
      save_context :user_board
      respond_with :message, text: "Недостаточно прав"
    end
    save_context :new_org_info
    if data.match?('^\+79\d{9}')
      org = Organization.where(phone: data).first || Organization.create(phone: data)
      remember_org_id(org.id)
      respond_with :message, text: 'Введите название организации'
    elsif data.match?('(^г\..+|^город.+)')
      current_org.update_attributes(address: data)
      respond_with :message, text: "Введите URL источника"
    elsif data.match?('^http.+')
      current_org.update_attributes(source: data)
      save_context :user_board
      respond_with :message, text: "Данные заполнены"
    else
      current_org.update_attributes(name: data)
      respond_with :message, text: "Введите адрес"
    end
    
  end

  def new_user(data, *)
    unless current_user(from).has_role? :admin
      save_context :user_board
      respond_with :message, text: "Недостаточно прав"
    end
    save_context :new_user
    if data.match?('^\+79\d{9}')
      user = User.where(phone: data).first.presence || User.create(phone: data, telegram_role_id: 4)
      unless user.new_record?
        save_context :user_board
        respond_with :message, text: 'Пользователь с таким номером уже существует'
      end
      remember_new_user_id(user.id)
      respond_with :message, text: "Введите имя"
    elsif data.match?('\D')
      user = User.find(new_user_id)
      user.update_attributes(name: data)
      respond_with :message, text: "Выберите роль"
    elsif data.match?('\d') && Role.all.pluck(:id).include?(data.to_i)
      user = User.find(new_user_id)
      user.update_attributes(telegram_role_id: data)
      save_context :user_board
      respond_with :message, text: "Пользователь успешно создан"  
    end
  end

  def callback_query(data)
    answer_data, answer_params = CallbackService.process(data)
    save_context :new_user if data.to_sym == :add_user
    save_context :new_org_info if data.to_sym == :add_info
    save_context :verify_org if data.to_sym == :check_db_info
    respond_with :message, text: answer_data, reply_markup: answer_params
  end

  def message(message)
    respond_with :message, text: t('.content', text: message['text'])
  end


  private

  def current_user(from)
    @current_user ||= User.where(telegram_id: from['id'])
  end

  def remember_org_id(id)
    session['org_id'] = id
  end

  def current_org
    Organization.find(session['org_id'])
  end

  def remember_new_user_id(id)
    session['new_user_id'] = id
  end

  def new_user_id
    session['new_user_id']
  end

  def session_key
    "#{bot.username}:#{chat['id']}:#{from['id']}" if chat && from
  end
end