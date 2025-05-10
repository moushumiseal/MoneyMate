class Wallet < ApplicationRecord
  extend T::Sig

  SUPPORTED_CURRENCIES = %w[SGD].freeze
  belongs_to :user
  has_many :transactions

  monetize :balance_cents, with_currency: :sgd

  validates :balance, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true, inclusion: { in: SUPPORTED_CURRENCIES }
end
