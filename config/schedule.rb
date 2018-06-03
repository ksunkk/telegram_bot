every 1.hours do
  runner "CsvService.send_backup"
end

every 1.day, at: '0:00 am' do
  runner "CsvService.cleanup"
end
