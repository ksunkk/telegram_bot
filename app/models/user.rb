class User < ApplicationRecord
  belongs_to :role, foreign_key: :telegram_role_id
  has_one :statistic, class_name: "Statistic", foreign_key: :telegram_user_id

  after_create do
    self.statistic = Statistic.create
  end

  def has_role?(code)
    self.role.code.to_sym == code
  end

  def can?(action_name)
  	self.role.has_permission?(action_name)
  end

  def check_or_set_telegram_info(tg_id, tg_chat_id)
    unless telegram_id && chat_id
      update_attributes(telegram_id: tg_id, chat_id: tg_chat_id)
    end
  end
end