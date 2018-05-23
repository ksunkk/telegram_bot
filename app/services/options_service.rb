class OptionsService
  def self.list_for(user)
    user_permissions = permissions.dup.delete_if { |i| !i['available_for'].include?(user.role.code.to_sym) }
    user_permissions.each_with_object([]) do |p, obj|
      obj << { text: p['action_name'].to_s, callback_data: p['id'] }
    end.permutation(3).to_a
  end

  # TODO: кэшировать
  def self.permissions
    @permissions ||= YAML.load_file("#{Rails.root}/config/permissions.yml")
  end
  private_class_method :permissions
end
