class User < ApplicationRecord
  extend T::Sig

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :trackable,
         :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist


  has_one :wallet, dependent: :destroy
  has_many :sent_transactions, class_name: 'Transaction', foreign_key: :sender_id
  has_many :received_transactions, class_name: 'Transaction', foreign_key: :receiver_id

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  after_create :create_wallet

  private

  sig { void }
  def create_wallet
    Wallet.create(user: self, balance: Money.new(0, 'SGD'), currency: 'SGD')
  end
end
