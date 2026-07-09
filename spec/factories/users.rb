FactoryBot.define do
  factory :user do
    idfa { SecureRandom.uuid }
    ban_status { :not_banned }
  end
end
