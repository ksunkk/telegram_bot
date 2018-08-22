module TelegramOrganizationMethods
  def update_org_info(data, *args, create: true)
    if data.match?('^\+7\d{10}')
      if create && Organization.where(phone: data, name: current_org.name).present?
        save_context :new_org_info
        respond_with :message, text: t('organization.exist')
        @current_user.statistic.dubles_count += 1
        @current_user.statistic.save
        return
      end
      current_org.update_attributes(phone: data)
      respond_with :message, text: t('organization.enter_source') if create
      respond_with :message, text: 'Номер обновлён', reply_markup: fix_org_keyboard unless create
    elsif data.match?('(^г\..+|^город.+|^Г.+|^Город.+|^г.+|^Г\..+)')
      current_org.update_attributes(address: "#{data} #{args.join(' ')}")
      respond_with :message, text: t('organization.enter_source') if create
      respond_with :message, text: 'Адрес обновлён', reply_markup: fix_org_keyboard unless create
    elsif data.match?('^http.+|^www.+')
      current_org.update_attributes(source: data)
      send_new_record_notification
      save_context :user_board
      respond_with :message, text: t('organization.saved'), reply_markup: user_keyboard if create
      respond_with :message, text: 'Источник обновлён', reply_markup: fix_org_keyboard unless create
    elsif data.match?('^\D+')
      if create
        org = Organization.where(name: data).where.not(phone: nil).first || Organization.new(name: data)
        org.update_attributes(name: "#{data} #{args.join(' ')}")
        org.added_by = @current_user.id
        org.save
        org.not_checked!
        remember_org_id(org.id)
        respond_with :message, text: t('organization.enter_phone')
      else
        current_org.update_attributes(name: "#{data} #{args.join(' ')}")
        respond_with :message, text: 'Название обновлено', reply_markup: fix_org_keyboard
      end
    else
      respond_with :message, text: 'Введёны некорректные данные.'
      save_context :new_org_info if create
      save_context :fix_org unless create
    end
  end

  def org_set_verification_status!(status)
    org = current_org
    fieldworker_stat = org.user.statistic.presence || org.user.create_statistic
    validator_stat = @current_user.statistic.presence || @current_user.create_statistic
    if status.to_sym == :invalid
      org.invalid_data!
      fieldworker_stat.invalid_count += 1
      validator_stat.corrections_count += 1
      response_keyboard = fix_org_keyboard
      response_message = 'Внесите исправления в запись'
    else
      org.valid_data!
      fieldworker_stat.valid_count += 1
      response_keyboard = user_keyboard
      response_message = t('data_saved')
    end
    validator_stat.validates_count += 1
    fieldworker_stat.save
    validator_stat.save
    respond_with :message, text: response_message, reply_markup: response_keyboard
    return
  end

  def org_validation(org_id: nil)
    unless @current_user.has_role?(:validator)|| @current_user.has_role?(:admin)
      save_context :user_board
      respond_with :message, text: t('access_error')
      return
    end
    if org_id
      org = Organization.find(org_id).first
      unless org.not_checked?
        respond_with :message, text: "Запись уже верифицирована", reply_markup: user_keyboard
        return
      end
    else
      org = Organization.needs_check.first
      unless org.presence
        respond_with :message, text: "Нет доступных для валидации записей", reply_markup: user_keyboard
        return
      end
    end
    remember_org_id(org.id)
    respond_with :message, text: "#{org.name}\n#{org.phone}\n#{org.address}\n#{org.source}", reply_markup: {
      inline_keyboard: [
        [
          { text: t('valid'), callback_data: 'valid_org' },
          { text: t('invalid'), callback_data: 'invalid_org' },
        ]
      ]
    }
    return
  end
end