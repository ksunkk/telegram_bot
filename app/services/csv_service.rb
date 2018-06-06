require 'csv'
# Сервис для работы с выгрузками
class CsvService
  # Плановый бэкап раз в час
  def self.send_backup
    admins_chats = User.where(telegram_role_id: 1).pluck(:chat_id)
    bot = Telegram.bot
    admins_chats.compact.each { |chat_id| bot.send_document(chat_id: chat_id, document: File.open(full_db)) }
  end

  def self.full_db
    file_name = "#{Time.now.to_i.to_s}.csv"
    ::CSV.open(file_name, 'wb:windows-1251:utf-8') do |csv|
      csv << Organization.attribute_names
      Organization.all.each do |record|
        csv << record.attributes.values
      end
      csv
    end
    file_name
  end

  def self.for_period(start_date, end_date)
    file_name = "#{Time.now.to_i.to_s}_#{start_date}#{end_date}.csv"
    orgs = Organization.where("created_at >= '#{start_date}'::date and created_at <= '#{end_date}'::date")
    ::CSV.open(file_name, 'wb:windows-1251:utf-8') do |csv|
      csv << Organization.attribute_names
      orgs.each do |record|
        csv << record.attributes.values
      end
      csv
    end
    file_name
  end

  def self.cleanup
    Dir.foreach(Rails.root) do |f|
      next unless f.include?('.csv')
      begin
        File.open(f, 'r') do |d|
          d.delete
        end
      rescue Errno::ENOENT
      end
    end
  end
end
