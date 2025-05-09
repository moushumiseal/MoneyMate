class Wallet < ApplicationRecord
  extend T::Sig

  SUPPORTED_CURRENCIES = %w[SGD].freeze
  belongs_to :user
  has_many :transactions

  monetize :balance_cents, with_currency: :sgd

  validates :balance, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true, inclusion: { in: SUPPORTED_CURRENCIES }

  sig { params(amount: Money).void }
  def deposit(amount)
    raise ArgumentError, 'Amount must be positive' if amount.negative?

    with_lock do
      self.balance += amount
      save!
      transactions.create!(amount_cents: amount.cents,
                           transaction_type: :deposit,
                           sender: nil,
                           receiver: self.user)
    end
  end

  sig { params(amount: Money).void }
  def withdraw(amount)
    raise ArgumentError, 'Amount must be positive' if amount.negative?

    with_lock do
      raise StandardError, 'Insufficient funds' if balance < amount

      self.balance -= amount
      save!
      transactions.create!(amount_cents: amount.cents,
                           transaction_type: :withdraw,
                           sender: self.user,
                           receiver: nil)
    end
  end

  sig { params(to_wallet: Wallet, amount: Money).void }
  def transfer(to_wallet, amount)
    raise ArgumentError, 'Amount must be positive' if amount.negative?
    raise StandardError, 'Cannot transfer to self' if self == to_wallet

    ApplicationRecord.transaction do
      withdraw(amount)
      to_wallet.deposit(amount)
      transactions.create!(amount: amount, transaction_type: :transfer, receiver: to_wallet.user)
    end
  end
end
