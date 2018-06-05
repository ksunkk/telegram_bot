module TelegramCallbackHelper

  ROLE_CALLBACKS = [:admin, :fieldworker, :validator].freeze
  NON_AUTO_CALLBACKS = [:check_db_info, :valid_org, :invalid_org, :get_db_backup, :get_stats, :feedback,
                        :fix_org_number, :fix_org_name, :fix_org_address, :fix_org_source, :end_org_edit, :upload_csv].freeze

  def callback_helper(data)
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
        save_context :db_backup
        answer_data = 'Введите дату начала и конца в формате дд.мм.гггг-дд.мм.гггг, для выгрузки всез записей введите любой символ'
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
        save_context :fix_org
        answer_data = 'Введите исправленный адрес'
      elsif data.to_sym == :fix_org_source
        save_context :fix_org
        answer_data = 'Введите исправленный источник'
      elsif data.to_sym == :end_org_edit
        answer_data = 'Выберите действие'
        answer_params = user_keyboard
      end
    elsif data.match?('reply_to_\d+')
      remember_reply_id(data.scan(/\d+/))
      save_context :send_reply
      answer_data = 'Введите текст ответа'
      answer_params = {}
    elsif data.match?('validate_org_\d+')
      remember_reply_id(data.scan(/\d+/))
      org_validation(org_id: data.scan(/\d+/))
    else
      answer_data, answer_params = CallbackAnswerService.process(data)
    end
    save_context :new_user if data.to_sym == :add_user
    save_context :new_org_info if data.to_sym == :add_info
    respond_with :message, text: answer_data, reply_markup: answer_params
  end
end