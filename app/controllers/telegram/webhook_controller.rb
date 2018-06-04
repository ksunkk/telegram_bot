class Telegram::WebhookController < Telegram::Bot::UpdatesController
  include Telegram::Bot::UpdatesController::MessageContext
  context_to_action!
  use_session!

  before_action -> { set_from(from) }
  before_action :set_current_user

  ROLE_CALLBACKS = [:admin, :fieldworker, :validator].freeze
  NON_AUTO_CALLBACKS = [:check_db_info, :valid_org, :invalid_org, :get_db_backup, :get_stats, :feedback,
                        :fix_org_number, :fix_org_name, :fix_org_address, :fix_org_source, :end_org_edit].freeze

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
    User.where(telegram_role_id: 1).pluck(:chat_id).each do |chat|
      respond_with :message, chat_id: chat, text: "От: #{from['id']}: #{args.join(' ')}"
    end
    respond_with :message, text: 'Сообщение отправлено', reply_markup: user_keyboard
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

  def callback_query(data)
    if ROLE_CALLBACKS.include?(data.to_sym)
      role_id = Role.where(code: data).first.id
      User.find(session['new_user_id']).update_attributes(telegram_role_id: role_id)
      answer_data = t('user.saved')
      answer_params = user_keyboard
      save_context :user_board
    elsif NON_AUTO_CALLBACKS.include?(data.to_sym)
      if data.to_sym == :check_db_info
        org_validation
      elsif data.to_sym == :valid_org
        org_set_verification_status!(:valid)
      elsif data.to_sym == :invalid_org
        org_set_verification_status!(:invalid)
      elsif data.to_sym == :get_db_backup
        send_db_backup
      elsif data.to_sym == :get_stats
        show_stats
      elsif data.to_sym == :feedback
        text_to_admin
      elsif data.to_sym == :fix_org_number
        save_context :fix_org
        answer_data = 'Введите исправленный номер телефона'
      elsif data.to_sym == :fix_org_name
        save_context :fix_org
        answer_data = 'Введите исправленное название'
      elsif data.to_sym == :fix_org_address
        save_context :fix_org_
        answer_data = 'Введите исправленный адрес'
      elsif data.to_sym == :fix_org_source
        save_context :fix_org
        answer_data = 'Введите исправленный источник'
      elsif data.to_sym == :end_org_edit
        answer_data = 'Выберите действие'
        answer_params = user_keyboard
      end
    else
      answer_data, answer_params = CallbackAnswerService.process(data)
    end
    save_context :new_user if data.to_sym == :add_user
    save_context :new_org_info if data.to_sym == :add_info
    respond_with :message, text: answer_data, reply_markup: answer_params
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
      stat = @current_user.statistic
      respond_with :message, text: t('statistic', valid_count: stat.valid_count, invalid_count: stat.invalid_count), reply_markup: user_keyboard
    end
    return
  end

  def update_org_info(data, *args, create: true)
    if data.match?('^\+7\d{10}')
      if create
        org = Organization.where(phone: data).first || Organization.new(phone: data)
        unless org.new_record?
          save_context :user_board
          respond_with :message, text: t('organization.exist')
          return
        end
        org.added_by = @current_user.id
        org.save
        org.not_checked!
        remember_org_id(org.id)
        respond_with :message, text: t('organization.enter_name')
      else
        current_org.update_attributes(phone: data)
        respond_with :message, text: 'Номер обновлён', reply_markup: fix_org_keyboard
        return
      end
    elsif data.match?('(^г\..+|^город.+|^Г.+|^Город.+|^г.+)')
      current_org.update_attributes(address: "#{data} #{args.join(' ')}")
      respond_with :message, text: t('organization.enter_source') if create
      respond_with :message, text: 'Адрес обновлён', reply_markup: fix_org_keyboard unless create
    elsif data.match?('^http.+')
      current_org.update_attributes(source: data)
      send_new_record_notification
      save_context :user_board
      respond_with :message, text: t('organization.saved'), reply_markup: user_keyboard if create
      respond_with :message, text: 'Источник обновлён', reply_markup: fix_org_keyboard unless create

    else
      current_org.update_attributes(name: data)
      respond_with :message, text: 'Источник обновлён', reply_markup: fix_org_keyboard unless create
      respond_with :message, text: t('organization.enter_address') if create
    end
  end

  def send_db_backup
    unless @current_user.has_role? :admin
      save_context :user_board
      respond_with :message, text: t('access_error')
    end
    csv_file_name = CsvService.full_db
    respond_with :document, document: File.open(csv_file_name), chat_id: @current_user.chat_id
    save_context :user_board
    respond_with :message, text: t('select_action'), reply_markup: user_keyboard
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

  def org_set_verification_status!(status)
    org = current_org
    fieldworker_stat = org.user.statistic.presence || org.user.create_statistic
    validator_stat = @current_user.statistic.presence || @current_user.create_statistic
    if status.to_sym == :invalid
      org.invalid_data!
      org.user.statistic.invalid_count += 1
      response_keyboard = fix_org_keyboard
    else
      org.valid_data!
      org.user.statistic.valid_count += 1
      response_keyboard = user_keyboard
    end
    org.user.statistic.save
    save_context :user_board
    respond_with :message, text: t('data_saved'), reply_markup: response_keyboard
    return
  end

  def org_validation
    unless @current_user.has_role?(:validator)|| @current_user.has_role?(:admin)
      save_context :user_board
      respond_with :message, text: t('access_error')
      return
    end
    org = Organization.needs_check.first
    remember_org_id(org.id)
    respond_with :message, text: "#{org.name}\n#{org.phone}\n#{org.address}", reply_markup: {
      inline_keyboard: [
        [
          { text: t('valid'), callback_data: 'valid_org' },
          { text: t('invalid'), callback_data: 'invalid_org' },
        ]
      ]
    }
    return
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

  def remember_new_user_id(id)
    session['new_user_id'] = id
  end

  def send_new_record_notification
    User.where(telegram_role_id: 2).pluck(:chat_id).each do |chat|
      respond_with :message, chat_id: chat, text: t('organization.new_record', name: current_org.name)
    end
  end

  def new_user_id
    session['new_user_id']
  end

  def session_key
    "#{bot.username}:#{chat['id']}:#{from['id']}" if chat && from
  end
end