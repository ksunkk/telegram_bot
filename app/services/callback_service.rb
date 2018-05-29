class CallbackService
  class << self
    METHOD_MAPPER = {
                      ru: :select_language,
                      en: :select_language,
                      add_user: :new_user,
                      add_info: :create_org_record,
                      check_db_info: :verify_info

                    }.each(&:freeze).freeze

    def process(data)
      @data = data.to_sym
      method_name = METHOD_MAPPER[@data]
      return ["unknown option", nil] unless method_name
      send method_name
    end

    private

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

    def new_user
    end

    def select_language
      I18n.locale = @data
      ["Введите номер телефона в формате +7XXXXXXXXXX", {}]
    end
  end
end