class Transaction < ApplicationRecord
  extend T::Sig

  belongs_to :wallet
  belongs_to :sender, class_name: 'User', optional: true
  belongs_to :receiver, class_name: 'User', optional: true
  belongs_to :receiver_wallet, class_name: 'Wallet', optional: true

  monetize :amount_cents, with_currency: :sgd

  validates :amount_cents, numericality: { greater_than: 0 }
  validates :currency, presence: true, inclusion: { in: Wallet::SUPPORTED_CURRENCIES }
  validate :validate_transaction_type
  validate :validate_wallet_ownership

  enum transaction_type: {
    deposit: 'deposit',
    withdraw: 'withdraw',
    transfer: 'transfer'
  }, _suffix: true

  enum status: {
    pending: 'pending',
    completed: 'completed',
    failed: 'failed',
    cancelled: 'cancelled'
  }, _suffix: true

  after_initialize :set_default_status, if: :new_record?

  private

  def set_default_status
    self.status ||= :pending
  end

  def validate_transaction_type
    case transaction_type
    when 'deposit'
      errors.add(:sender, "must be nil for deposits") if sender.present?
      errors.add(:receiver, "must be present for deposits") if receiver.blank?
      errors.add(:receiver_wallet, "must be nil for deposits") if receiver_wallet.present?
    when 'withdraw'
      errors.add(:sender, "must be present for withdrawals") if sender.blank?
      errors.add(:receiver, "must be nil for withdrawals") if receiver.present?
      errors.add(:receiver_wallet, "must be nil for withdrawals") if receiver_wallet.present?
    when 'transfer'
      errors.add(:sender, "must be present for transfers") if sender.blank?
      errors.add(:receiver, "must be present for transfers") if receiver.blank?
      errors.add(:receiver_wallet, "must be present for transfers") if receiver_wallet.blank?
      errors.add(:base, "sender and receiver cannot be the same") if sender == receiver
    end
  end

  def validate_wallet_ownership
    if transaction_type == 'transfer' && receiver_wallet.present?
      unless receiver_wallet.user == receiver
        errors.add(:receiver_wallet, "must belong to the receiver")
      end
    end
    if sender.present? && wallet.present?
      unless wallet.user == sender
        errors.add(:wallet, "must belong to the sender")
      end
    end
  end
end