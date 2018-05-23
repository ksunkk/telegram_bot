class Role < ApplicationRecord
  has_and_belongs_to_many :permissions
  has_many :users, foreign_key: :telegram_role_id
  def has_permission?(action_name)
    permissions.pluck(:action_name).include?(action_name.to_sym)
  end
end
