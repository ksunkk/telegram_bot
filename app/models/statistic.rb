class Statistic < ApplicationRecord
  self.table_name_prefix = ''

  belongs_to :user, foreign_key: :telegram_user_id

  def to_s
  	<<-STAT
  	 Всего создано записей: #{valid_count + invalid_count}
     Из них #{valid_count} верифицировано, #{invalid_count} неверифицировано
  	STAT
  end
end
