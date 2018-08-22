class Statistic < ApplicationRecord
  self.table_name_prefix = ''

  belongs_to :user, foreign_key: :telegram_user_id

  def to_s
    total_count = valid_count.to_i + invalid_count.to_i
    default = <<-STR.squish!
        Всего добавлено записей: #{ total_count }\nИз них #{ valid_count } проверено, #{ total_count - valid_count.to_i } непроверено.\n
        Уникальных записей: #{ total_count - dubles_count.to_i}, неуникальных записей: #{ dubles_count.to_i }
    STR
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
