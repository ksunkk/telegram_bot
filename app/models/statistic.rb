class Statistic < ApplicationRecord
  self.table_name_prefix = ''

  belongs_to :user, foreign_key: :telegram_user_id
end
