# Clear existing data
puts "Clearing existing data..."
Transaction.destroy_all
Wallet.destroy_all
User.destroy_all
JwtDenylist.destroy_all

# Create sample JwtDenylist entries
puts "Creating JWT denylist entries..."
JwtDenylist.create!(
  jti: "7fa8c4d5e6f7g8h9i0j1k2l3m4n5o6p7",
  exp: 1.day.ago
)
JwtDenylist.create!(
  jti: "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6",
  exp: 2.days.ago
)

# Create sample users
puts "Creating users..."
users = [
  {
    name: "John Smith",
    email: "john.smith@gmail.com",
    password: "password123",
    confirmed_at: Time.current
  },
  {
    name: "Jane Doe",
    email: "janedoe85@hotmail.com",
    password: "password123",
    confirmed_at: Time.current
  },
  {
    name: "Michael Johnson",
    email: "michael.johnson@example.com",
    password: "password123",
    confirmed_at: Time.current
  },
  {
    name: "Emily Williams",
    email: "emily.williams2023@gmail.com",
    password: "password123",
    confirmed_at: Time.current
  },
  {
    name: "Robert Brown",
    email: "robert_brown@hotmail.com",
    password: "password123",
    confirmed_at: nil,
    confirmation_sent_at: 1.day.ago,
    confirmation_token: "conf_token_rb456"
  }
]

created_users = users.map do |user_data|
  user = User.create!(
    name: user_data[:name],
    email: user_data[:email],
    password: user_data[:password],
    encrypted_password: Devise::Encryptor.digest(User, user_data[:password]),
    confirmed_at: user_data[:confirmed_at],
    confirmation_sent_at: user_data[:confirmation_sent_at],
    confirmation_token: user_data[:confirmation_token],
    created_at: rand(1..60).days.ago,
    updated_at: rand(1..10).days.ago,
    sign_in_count: rand(1..20),
    current_sign_in_at: rand(1..5).days.ago,
    last_sign_in_at: rand(6..10).days.ago,
    current_sign_in_ip: "127.0.0.1",
    last_sign_in_ip: "127.0.0.1"
  )
  puts "Created user: #{user.name}"
  user
end

puts "Updating wallet balances..."
wallet_balances = [10_000, 20_000, 15_000, 5_000, 7_500]
created_users.each_with_index do |user, idx|
  # Wallets are automatically created by the after_create callback
  user.wallet.update!(balance_cents: wallet_balances[idx])
  puts "→ Updated wallet for #{user.name}: #{Money.new(wallet_balances[idx], 'SGD').format}"
end

puts "Creating sample transactions..."
Transaction.create!(
  transaction_type: "credit",
  receiver: created_users[0],
  wallet: created_users[0].wallet,
  amount_cents: 5000,
  status: :completed
)

Transaction.create!(
  transaction_type: "debit",
  sender: created_users[1],
  wallet: created_users[1].wallet,
  amount_cents: 2000,
  status: :completed
)

Transaction.create!(
  transaction_type: "debit",
  sender: created_users[2],
  receiver: created_users[3],
  wallet: created_users[2].wallet,
  receiver_wallet: created_users[3].wallet,
  amount_cents: 1000,
  status: :completed
)

Transaction.create!(
  transaction_type: "credit",
  sender: created_users[2],
  receiver: created_users[3],
  wallet: created_users[2].wallet,
  receiver_wallet: created_users[3].wallet,
  amount_cents: 1000,
  status: :completed
)

Transaction.create!(
  transaction_type: "debit",
  sender: created_users[0],
  receiver: created_users[1],
  wallet: created_users[0].wallet,
  receiver_wallet: created_users[1].wallet,
  amount_cents: 750,
  status: :completed
)

Transaction.create!(
  transaction_type: "credit",
  sender: created_users[0],
  receiver: created_users[1],
  wallet: created_users[0].wallet,
  receiver_wallet: created_users[1].wallet,
  amount_cents: 750,
  status: :completed
)

puts "Done seeding the database!"