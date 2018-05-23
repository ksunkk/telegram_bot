class User < ApplicationRecord
  belongs_to :role, foreign_key: :telegram_role_id

  def has_role?(code)
    self.role.code == code
  end

  def can?(action_name)
  	self.role.has_permission?(action_name)
  end
end