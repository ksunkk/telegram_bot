class CallbackAnswerService
  class << self
    AVAILABLE_METHODS = [:set_lang_ru, :set_lang_en, :add_user, :add_info, :get_stats].freeze

    def process(data)
      @method_name = data.to_sym
      if AVAILABLE_METHODS.include?(@method_name)
        send @method_name
      else
        return ["unknown option", nil] unless method_name
      end
    end

    private

    def stats
      ["Введите номер телефона:", nil]
    end

    def check_db_info
      ["Введите номер телефона:", nil]
    end

    def add_info
      ["Введите номер телефона:", nil]
    end

    def verify_info
      org = Organization.where(is_verified: false).first
      unless org
        return ["Нет неверифицированных записей", {}]
      else
        return ["#{org.phone}\norg.name\norg.address\norg.source", {
                  inline_keyboard: [
                    { text: "Верно", callback_data: "valid-#{org.id}"}
                  ]
                }]
      end
    end

    def add_user
      ["Введите номер телефона:", nil]
    end

    def set_lang_ru
      I18n.locale = :ru
      ["Введите номер телефона в формате +7XXXXXXXXXX", {}]
    end

    def set_lang_en
      I18n.locale = :en
      ["Введите номер телефона в формате +7XXXXXXXXXX", {}]
    end
  end
end