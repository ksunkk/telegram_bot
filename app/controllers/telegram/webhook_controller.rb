class Telegram::WebhookController < Telegram::Bot::UpdatesController
  include Telegram::Bot::UpdatesController::MessageContext
  context_to_action!
  use_session!

  before_action -> { set_from(from) }
  before_action :set_current_user

  ROLE_CALLBACKS = [:admin, :fieldworker, :validator].freeze
  NON_AUTO_CALLBACKS = [:check_db_info, :valid_org, :invalid_org, :get_db_backup, :get_stats].freeze

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
        reply_keyboard = {
          inline_keyboard: [
            OptionsService.list_for(user)
          ]
        }
      else
        # TODO: экшн для связи с администратором
        save_context :login
        reply_txt = t('user.not_found')
        reply_keyboard = {}
      end
    else
      save_context :login
      reply_txt = t('user.invalid_phone')
      reply_keyboard = {}
    end
    respond_with :message, text: reply_txt, reply_markup: reply_keyboard
  end



  def user_board(*)
    respond_with :message, text: t('select_action'), reply_markup: {
      inline_keyboard: [
        OptionsService.list_for(@current_user)
      ]
    }
  end

  def stats(phone, *)
    stat = User.where(phone: phone).first.statistic.to_s
    respond_with :message, text: stat, reply_markup: {
      inline_keyboard: [
        OptionsService.list_for(@current_user)
      ]
    }
  end

  def new_org_info(data, *)
    unless @current_user.has_role?(:fieldworker) || @current_user.has_role?(:admin)
      save_context :user_board
      respond_with :message, text: t('access_error')
    end
    save_context :new_org_info
    if data.match?('^\+7\d{10}')
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
      return
    elsif data.match?('(^г\..+|^город.+|^Г.+|^Город.+|^г.+)')
      current_org.update_attributes(address: data)
      respond_with :message, text: t('organization.enter_source')
    elsif data.match?('^http.+')
      current_org.update_attributes(source: data)
      save_context :user_board
      respond_with :message, text: t('organization.saved')
    else
      current_org.update_attributes(name: data)
      respond_with :message, text: t('organization.enter_address')
    end
    
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
      save_context :user_board
    elsif NON_AUTO_CALLBACKS.include?(data.to_sym)
      if data.to_sym == :check_db_info
        unless current_user(from).has_role? :verificator
          save_context :user_board
          respond_with :message, text: t('access_error')
        end
        org = Organization.needs_check.first
        remember_org_id(org.id)
        answer_data = "#{org.name}\n#{org.phone}\n#{org.address}"
        answer_params = {
          inline_keyboard: [
            [
              { text: t('valid'), callback_data: 'valid_org' },
              { text: t('invalid'), callback_data: 'invalid_org' },
            ]
          ]
        }
      elsif data.to_sym == :valid_org
        org = current_org
        org.valid_data!
        org.user.statistic.valid_count += 1
        org.user.statistic.save
        save_context :user_board
        answer_data = t('data.saved')
        answer_params = {
            inline_keyboard: [
              OptionsService.list_for(@current_user)
            ]
          }
      elsif data.to_sym == :invalid_org
        org = current_org
        org.invalid_data!
        org.user.statistic.invalid_count += 1
        org.user.statistic.save
        save_context :user_board
        answer_data = t('data.saved')
        answer_params = {
            inline_keyboard: [
              OptionsService.list_for(@current_user)
            ]
          }
      elsif data.to_sym == :get_db_backup
        unless @current_user.has_role? :admin
          save_context :user_board
          respond_with :message, text: t('access_error')
        end
        csv_file_name = CsvService.full_db
        respond_with :document, document: File.open(csv_file_name), chat_id: @current_user.chat_id
        save_context :user_board
        answer_data = t('select_action')
        answer_params = {
          inline_keyboard: [
            OptionsService.list_for(@current_user)
          ]
        }
        return
      elsif data.to_sym == :get_stats
        if @current_user.has_role? :admin
          answer_data = t('user.enter_phone')
          answer_params = {}
        else
          stat = @current_user.statistic.to_s
          respond_with :message, text: t('statistic', valid_count: stat.valid_count, invalid_count: stat.invalid_count)
        end
      end
    else
      answer_data, answer_params = CallbackAnswerService.process(data)
    end
    save_context :new_user if data.to_sym == :add_user
    save_context :new_org_info if data.to_sym == :add_info
    save_context :stats if data.to_sym == :get_stats
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