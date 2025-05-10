# frozen_string_literal: true
# typed: true

class UserWalletService
  extend T::Sig

  sig { params(user: User).void }
  def initialize(user)
    @user = user
  end

  sig { returns(Hash) }
  def balance_details
    {
      balance: @user.wallet.balance.format,
      amount_numeric: @user.wallet.balance.to_f,
      currency: @user.wallet.currency
    }
  end
end