class Organization < ApplicationRecord
  self.table_name_prefix = ''
  has_many :photos
end
