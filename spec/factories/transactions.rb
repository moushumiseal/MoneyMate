FactoryBot.define do
  factory :transaction do
    transaction_type { "MyString" }
    amount { "9.99" }
    sender_id { 1 }
    receiver_id { 1 }
    wallet { nil }
  end
end
