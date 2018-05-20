class Role < ApplicationRecord
  has_and_belongs_to_many :permissions

  def has_permission?(action_name)
    permissions.pluck(:action_name).include?(action_name.to_sym)
  end
end
