# frozen_string_literal: true
# typed: true

class UsersController < ApplicationController
  extend T::Sig

  before_action :set_user
  before_action :authenticate_api_user!
  before_action :authorize_user_access!

  sig { void }
  def balance
    render json: {
      balance: @user.wallet.balance.format,
      amount_numeric: @user.wallet.balance.to_f,
      currency: @user.wallet.currency
    }
  end

  sig { void }
  def transactions
    transactions = @user.wallet.transactions.order(created_at: :desc)

    render json: transactions.map { |txn|
      {
        id: txn.id,
        type: txn.transaction_type,
        amount: txn.amount.format,
        amount_numeric: txn.amount.to_f,
        currency: txn.currency,
        sender: txn.sender&.email,
        receiver: txn.receiver&.email,
        created_at: txn.created_at
      }
    }
  end

  private

  sig { void }
  def set_user
    @user = User.find(params[:id])
  end

  sig { returns(T::Boolean) }
  def authorize_user_access!
    unless @user == current_api_user
      render json: { error: 'Unauthorized' }, status: :unauthorized
      return false
    end
    true
  end
end