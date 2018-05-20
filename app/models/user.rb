class User < ApplicationRecord
  has_one :role, class_name: 'Role', foreign_key: :telegram_role_id

  def has_role?(code)
    self.role.code == code
  end

  def can?(action_name)
  	self.role.has_permission?(action_name)
  end
end