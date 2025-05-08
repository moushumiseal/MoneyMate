class User < ApplicationRecord
  has_one :wallet, dependent: :destroy
  has_many :transactions, foreign_key: :sender_id

  after_create :create_wallet

  private
  def create_wallet
    Wallet.create(user: self, balance: 0.0)
  end
end
