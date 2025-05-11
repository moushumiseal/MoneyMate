class Transaction < ApplicationRecord
  extend T::Sig

  belongs_to :wallet
  belongs_to :sender, class_name: 'User', optional: true
  belongs_to :receiver, class_name: 'User', optional: true
  belongs_to :receiver_wallet, class_name: 'Wallet', optional: true

  monetize :amount_cents, with_currency: :sgd

  validates :amount_cents, numericality: { greater_than: 0 }
  validates :currency, presence: true, inclusion: { in: Wallet::SUPPORTED_CURRENCIES }

  enum transaction_type: {
    credit: 'credit',
    debit: 'debit',
  }, _suffix: true

  enum status: {
    pending: 'pending',
    completed: 'completed',
    failed: 'failed',
    cancelled: 'cancelled',
  }, _suffix: true

  after_initialize :set_default_status, if: :new_record?

  private

  def set_default_status
    self.status ||= :pending
  end
end