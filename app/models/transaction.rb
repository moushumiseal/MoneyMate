class Transaction < ApplicationRecord
  extend T::Sig

  belongs_to :wallet
  belongs_to :sender, class_name: 'User', optional: true
  belongs_to :receiver, class_name: 'User', optional: true

  monetize :amount_cents, with_currency: :sgd

  validates :amount_cents, numericality: { greater_than: 0 }
  validates :currency, presence: true, inclusion: { in: Wallet::SUPPORTED_CURRENCIES }

  enum transaction_type: {
    deposit: 'deposit',
    withdraw: 'withdraw',
    transfer: 'transfer'
  }, _suffix: true
end
