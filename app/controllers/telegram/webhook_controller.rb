class Telegram::WebhookController < Telegram::Bot::UpdatesController
  include Telegram::Bot::UpdatesController::MessageContext
  include ::TelegramCallbackHelper
  include ::TelegramOrganizationMethods

  context_to_action!
  use_session!

  before_action -> { set_from(from) }
  before_action :set_current_user

  def start(*)
    save_context :login
    respond_with :message, text: t('select_language'), reply_markup: {
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
        reply_txt = t('hello', name: user.name)
        reply_keyboard = user_keyboard
      else
        save_context :login
        reply_txt = t('user.not_found')
        reply_keyboard = feedback_keyboard
      end
    else
      save_context :login
      reply_txt = t('user.invalid_phone')
      reply_keyboard = {}
    end
    respond_with :message, text: reply_txt, reply_markup: reply_keyboard
  end

  def feedback(*args)
    User.where(telegram_role_id: 1).pluck(:chat_id).each do |admin_chat|
      respond_to_chat_with :message, admin_chat, text: "От: #{from['id']}: #{args.join(' ')}", reply_markup: { 
        inline_keyboard: [
          [
            { text: 'Ответить', callback_data: "reply_to_#{from['id']}" },
          ]
        ]
      }
    end
    respond_with :message, text: 'Сообщение отправлено', reply_markup: user_keyboard
  end

  def respond_to_chat_with(type, dest_chat, params)
    chat_id = dest_chat
    bot.public_send("send_#{type}", params.merge(chat_id: chat_id))
  end

  def user_board(*)
    respond_with :message, text: t('select_action'), reply_markup: user_keyboard
  end

  def stats(phone, *)
    stat = User.where(phone: phone).first.statistic.to_s || "Для данного пользвоателя не найдено статистики, обратитесь к администратору"
    respond_with :message, text: stat, reply_markup: user_keyboard
  end

  def new_org_info(data, *args)
    unless @current_user.has_role?(:fieldworker) || @current_user.has_role?(:admin)
      save_context :user_board
      respond_with :message, text: t('access_error')
    end
    save_context :new_org_info
    update_org_info(data, *args, create: true)
    return
  end

  def new_user(data, *)
    unless @current_user.has_role? :admin
      save_context :user_board
      respond_with :message, text: t('access_error')
      return
    end
    save_context :new_user
    if data.match?('^\+79\d{9}')
      user = User.where(phone: data).first.presence || User.new(phone: data, telegram_role_id: 4)
      unless user.new_record?
        save_context :user_board
        respond_with :message, text: t('user.exist')
        return
      end
      user.save
      remember_new_user_id(user.id)
      respond_with :message, text: t('user.enter_name')
    elsif data.match?('\D')
      user = User.find(new_user_id)
      user.update_attributes(name: data)
      respond_with :message, text: t('user.select_role'), reply_markup: {
        inline_keyboard: [
          [
            { text: t('roles.admin'), callback_data: 'admin' },
            { text: t('roles.validator'), callback_data: 'validator' },
          ],
          [
            { text: t('roles.fieldworker'), callback_data: 'fieldworker' },
          ],
        ],
      }
    end
  end

  def db_backup(data, *args)
    unless @current_user.has_role? :admin
      save_context :user_board
      respond_with :message, text: t('access_error')
    end
    if data.match?('\d{2}\.\d{2}\.\d{4}-\d{2}\.\d{2}\.\d{4}')
      start_dt, end_dt = data.split('-').map { |s| Date.parse(s) }
      csv_file_name = CsvService.for_period(start_dt, end_dt)
    else
      csv_file_name = CsvService.full_db
    end
    respond_with :document, document: File.open(csv_file_name), chat_id: @current_user.chat_id
    save_context :user_board
    respond_with :message, text: t('select_action'), reply_markup: user_keyboard
    return
  end

  def callback_query(data)
    callback_helper(data)
  end

  def send_reply(*args)
    respond_to_chat_with :message, reply_id, text: "Ответ администратора на Ваше обращение:\n#{args.join(' ')}"
  end

  def fix_org(data, *args)
    save_context :fix_org
    update_org_info(data, *args, create: false)
  end

  private

  def text_to_admin
    save_context :feedback
    respond_with :message, text: 'Опишите Вашу проблему'
  end

  def show_stats
    if @current_user.has_role? :admin
      save_context :stats
      respond_with :message, text: t('user.enter_phone')
    else
      stat = @current_user.statistic.to_s
      respond_with :message, text: stat, reply_markup: user_keyboard
    end
    return
  end


  def fix_org_keyboard
    { inline_keyboard: [
        [
          { text: 'Исправить номер', callback_data: 'fix_org_number' },
          { text: 'Исправить название', callback_data: 'fix_org_name' },
        ],
        [
          { text: 'Исправить адрес', callback_data: 'fix_org_address' },
          { text: 'Исправиь источник', callback_data: 'fix_org_source' },
        ],
        [
          { text: 'Завершить редактирование', callback_data: 'end_org_edit' }
        ]
    ] }
  end

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

  def user_keyboard
    {
      inline_keyboard: [
        OptionsService.list_for(@current_user),
        [ { text: 'Связаться с администратором', callback_data: 'feedback' } ]
      ]
    }
  end

  def feedback_keyboard
    { inline_keyboard: [ [ { text: 'Связаться с администратором', callback_data: 'feedback' } ] ] }
  end

  def remember_reply_id(raw_id)
    id = raw_id.first.to_i
    session['reply_id'] = id
  end

  def reply_id
    session['reply_id']
  end

  def remember_new_user_id(id)
    session['new_user_id'] = id
  end

  def send_new_record_notification
    User.where(telegram_role_id: 1).pluck(:chat_id).compact.each do |reply_chat|
      respond_to_chat_with :message, reply_chat, text: t('organization.new_record', name: current_org.name),
                                     reply_markup: { inline_keyboard: [ [ 
                                      { text: 'Проверить', callback_data: "validate_org_#{current_org.id}"} 
                                     ] ] }
    end
  end

  def new_user_id
    session['new_user_id']
  end

  def session_key
    "#{bot.username}:#{chat['id']}:#{from['id']}" if chat && from
  end
end
