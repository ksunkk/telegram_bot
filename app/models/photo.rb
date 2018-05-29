class Photo < ApplicationRecord
  self.table_name_prefix = ''
  mount_uploader :photo, BaseUploader  
end
