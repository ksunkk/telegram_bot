class OptionsService
  def self.list_for(user)
    user_permissions = permissions.dup.keep_if { |i| i['available_for'].include?(user.role.code.to_sym) && i['show'] }
    user_permissions.each_with_object([]) do |p, obj|
      obj << { text: I18n.t("actions.#{p['action_name'].to_s}"), callback_data: p['action_name'] }
    end
  end

  def self.permissions
    @permissions ||= YAML.load_file("#{Rails.root}/config/permissions.yml")
  end
  private_class_method :permissions
end
