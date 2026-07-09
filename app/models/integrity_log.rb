class IntegrityLog < ApplicationRecord
  self.record_timestamps = false

  validates :idfa, :ban_status, :created_at, presence: true
end
