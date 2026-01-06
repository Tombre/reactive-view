# frozen_string_literal: true

# Seed some example users for the ReactiveView demo

puts 'Creating example users...'

users = [
  { name: 'Alice Johnson', email: 'alice@example.com' },
  { name: 'Bob Smith', email: 'bob@example.com' },
  { name: 'Carol Williams', email: 'carol@example.com' },
  { name: 'David Brown', email: 'david@example.com' },
  { name: 'Eva Martinez', email: 'eva@example.com' },
  { name: 'Frank Davis', email: 'frank@example.com' },
  { name: 'Grace Wilson', email: 'grace@example.com' },
  { name: 'Henry Taylor', email: 'henry@example.com' }
]

users.each do |user_attrs|
  User.find_or_create_by!(email: user_attrs[:email]) do |user|
    user.name = user_attrs[:name]
  end
end

puts "Created #{User.count} users"
