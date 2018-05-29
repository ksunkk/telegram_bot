class User < ApplicationRecord
  belongs_to :role, foreign_key: :telegram_role_id
  has_one :statistic, class_name: "Statistic", foreign_key: :telegram_user_id

  after_create do
    self.statistic = Statistic.create
  end

  def has_role?(code)
    self.role.code == code
  end

  def can?(action_name)
  	self.role.has_permission?(action_name)
  end
end