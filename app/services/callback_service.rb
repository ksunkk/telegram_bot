class CallbackService
  class << self
    METHOD_MAPPER = {
                      ru: :select_language,
                      en: :select_language
                    }.each(&:freeze).freeze

    def process(data)
      @data = data.to_sym
      method_name = METHOD_MAPPER[@data]
      return ["unknown option", nil] unless method_name
      send method_name
    end

    private

    def select_language
      I18n.locale = @data
      ["Введите номер телефона в формате +7XXXXXXXXXX", nil]
    end
  end
end