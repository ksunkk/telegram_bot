class Statistic < ApplicationRecord
  self.table_name_prefix = ''

  belongs_to :user, foreign_key: :telegram_user_id

  def to_s
    default = "Всего добавлено записей: #{valid_count.to_i + invalid_count.to_i}\nИз них #{valid_count} верифицировано, #{invalid_count.to_i} неверифицировано\nДобавлений неуникальных записей: #{dubles_count.to_i}"
    extended_stat = "Проверено записей: #{validates_count.to_i}, из них отредактировано: #{corrections_count.to_i}"
    if user.has_role? :fieldworker
      default
    elsif user.has_role? :validator
      extended_stat
    else
      "#{default}\n#{extended_stat}"
    end
  end
end
