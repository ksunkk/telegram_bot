class Organization < ApplicationRecord
  enum check_status: [:not_checked, :valid_data, :invalid_data]

  scope :needs_check, -> { where(check_status: check_statuses.values_at(:not_checked)) }

  belongs_to :user, class_name: 'User', foreign_key: :added_by

  self.table_name_prefix = ''
  has_many :photos
end
