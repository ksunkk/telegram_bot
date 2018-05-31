require 'csv'
class CsvService
  # Выгрузка всех записей
  def self.full_db
    file_name = "#{Time.now.to_i.to_s}.csv"
    ::CSV.open(file_name, 'wb') do |csv|
      csv << Organization.attribute_names
      Organization.all.each do |record|
        csv << record.attributes.values
      end
      csv
    end
    file_name
  end
end
