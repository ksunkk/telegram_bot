class Telegram::WebhookController < Telegram::Bot::UpdatesController
  include Telegram::Bot::UpdatesController::MessageContext
  context_to_action!
  use_session!

  before_action -> { set_from(from) }
  before_action :set_current_user

  ROLE_CALLBACKS = [:admin, :fieldworker, :validator].freeze
  NON_AUTO_CALLBACKS = [:check_db_info, :valid_org, :invalid_org].freeze

  def start(*)
    save_context :login
    respond_with :message, text: 'Выберите язык:', reply_markup: {
      inline_keyboard: [
        [
          { text: 'Русский', callback_data: 'set_lang_ru' },
          { text: 'English', callback_data: 'set_lang_en' },
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
        user.check_or_set_telegram_info(from['id'], chat['id'])
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
        OptionsService.list_for(@current_user)
      ]
    }
  end

  def csv_db(*)
    unless current_user(from).has_role? :admin
      save_context :user_board
      respond_with :message, text: "Недостаточно прав"
    end
    csv_data = CsvService.full_db
    reply_with :file, csv_data.force_encoding('UTF-8'),
                      :type => 'tмая сталоext/csv; charset=UTF-8; header=present',
                      :disposition => "attachment;"
  end

  # TODO: уточнить как быть в случае пришло уведомление что ВЕРИФИЦИРУЙ -> а это уже верифицировали -> што делать
  # И каким образом дополняются поля
  def verify_org(*)
    unless current_user(from).has_role? :verificator
      save_context :user_board
      respond_with :message, text: "Недостаточно прав"
    end

  end

  def stats(*)
    if current_user(from).has_role? :admin
    else
      stat = current_user(from).statistic
      respond_with :message, text: "верифицировано: #{stat.valid_count},\nНеверифицировано: #{stat.valid_count}"
    end
  end

  def new_org_info(data, *)
    unless @current_user.has_role?(:fieldworker) || @current_user.has_role?(:admin)
      save_context :user_board
      respond_with :message, text: "Недостаточно прав"
    end
    save_context :new_org_info
    if data.match?('^\+7\d{10}')
      org = Organization.where(phone: data).first || Organization.new(phone: data)
      unless org.new_record?
        save_context :user_board
        respond_with :message, text: 'Организация с таким номером уже существует'
        return
      end
      org.save
      remember_org_id(org.id)
      respond_with :message, text: 'Введите название организации'
      return
    elsif data.match?('(^г\..+|^город.+|^Г.+|^Город.+|^г.+)')
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
    unless @current_user.has_role? :admin
      save_context :user_board
      respond_with :message, text: "Недостаточно прав"
      return
    end
    save_context :new_user
    if data.match?('^\+79\d{9}')
      user = User.where(phone: data).first.presence || User.new(phone: data, telegram_role_id: 4)
      unless user.new_record?
        save_context :user_board
        respond_with :message, text: 'Пользователь с таким номером уже существует'
        return
      end
      user.save
      remember_new_user_id(user.id)
      respond_with :message, text: "Введите имя"
    elsif data.match?('\D')
      user = User.find(new_user_id)
      user.update_attributes(name: data)
      respond_with :message, text: "Выберите роль", reply_markup: {
        inline_keyboard: [
          [
            { text: 'Администратор', callback_data: 'admin' },
            { text: 'Проверяющий', callback_data: 'validator' },
          ],
          [
            { text: 'Полевой сотрудник', callback_data: 'fieldworker' },
          ],
        ],
      }
    elsif data.match?('\d') && Role.all.pluck(:id).include?(data.to_i)
      user = User.find(new_user_id)
      user.update_attributes(telegram_role_id: data)
      save_context :user_board
      respond_with :message, text: "Пользователь успешно создан"  
    end
  end

  def callback_query(data)
    if ROLE_CALLBACKS.include?(data.to_sym)
      role_id = Role.where(code: data).first.id
      User.find(session['new_user_id']).update_attributes(telegram_role_id: role_id)
      answer_data = "Пользователь успешно сохранен!"
      save_context :user_board
    elsif NON_AUTO_CALLBACKS.include?(data.to_sym)
      if data.to_sym == :check_db_info
        org = Organization.needs_check.first
        remember_org_id(org.id)
        answer_data = "#{org.name}\n#{org.phone}\n#{org.address}"
        answer_params = {
          inline_keyboard: [
            [
              { text: 'Верно', callback_data: 'valid_org' },
              { text: 'Неверно', callback_data: 'invalid_org' },
            ]
          ]
        }
      elsif data.to_sym == :valid_org
        org = current_org
        org.valid_data!
        org.added_by.stat.valid_count += 1
        org.added_by.stat.save
        save_context :user_board
        answer_data = "Данные сохранены"
        answer_params = {
            inline_keyboard: [
              OptionsService.list_for(@current_user)
            ]
          }
      elsif data.to_sym == :invalid_org
        org = current_org
        org.invalid_data!
        org.added_by.stat.invalid_count += 1
        org.added_by.stat.save
        save_context :user_board
        answer_data = "Данные сохранены"
        answer_params = {
            inline_keyboard: [
              OptionsService.list_for(@current_user)
            ]
          }
      end
    else
      answer_data, answer_params = CallbackAnswerService.process(data)
    end
    save_context :new_user if data.to_sym == :add_user
    save_context :new_org_info if data.to_sym == :add_info
    save_context :stats if data.to_sym == :get_stats
    save_context :verify_org if data.to_sym == :check_db_info
    respond_with :message, text: answer_data, reply_markup: answer_params
  end

  def message(message)
    respond_with :message, text: t('.content', text: message['text'])
  end


  private

  def set_from(tg_data)
    @from = tg_data
  end

  def set_current_user
    @current_user = User.where(telegram_id: @from['id']).first
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