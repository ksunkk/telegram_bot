class CallbackService
  class << self
    METHOD_MAPPER = {
                      ru: :select_language,
                      en: :select_language,
                      add_user: :new_user,
                      add_info: :create_org_record

                    }.each(&:freeze).freeze

    def process(data)
      @data = data.to_sym
      method_name = METHOD_MAPPER[@data]
      return ["unknown option", nil] unless method_name
      send method_name
    end

    private

    def new_user
    end

    def select_language
      I18n.locale = @data
      ["Введите номер телефона в формате +7XXXXXXXXXX", nil]
    end
  end
end