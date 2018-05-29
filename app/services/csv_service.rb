class CsvService
  # Выгрузка всех записей
  def self.full_db
    CSV.generate do |csv|
      csv << Organization.model.attribute_names
      Organization.all.each do |record|
        csv << record.attributes.values
      end
    end
  end
end
