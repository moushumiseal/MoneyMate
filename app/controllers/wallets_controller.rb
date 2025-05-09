# frozen_string_literal: true
# typed: true

class WalletsController < ApplicationController
  extend T::Sig

  before_action :set_wallet
  before_action :authenticate_api_user!
  before_action :authorize_wallet_access!

  sig { void }
  def deposit
    amount = Money.from_amount(params[:amount].to_f, 'SGD')

    @wallet.deposit(amount)

    render json: {
      balance: @wallet.balance.format,
      amount_numeric: @wallet.balance.to_f,
      currency: @wallet.currency
    }
  end

  sig { void }
  def withdraw
    amount = Money.from_amount(params[:amount].to_f, 'SGD')

    begin
      @wallet.withdraw(amount)
      render json: {
        balance: @wallet.balance.format,
        amount_numeric: @wallet.balance.to_f,
        currency: @wallet.currency
      }
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  sig { void }
  def transfer
    receiver = User.find(params[:receiver_id])
    amount = Money.from_amount(params[:amount].to_f, 'SGD')

    begin
      @wallet.transfer(receiver.wallet, amount)
      render json: {
        balance: @wallet.balance.format,
        amount_numeric: @wallet.balance.to_f,
        currency: @wallet.currency
      }
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  private

  sig { void }
  def set_wallet
    @wallet = Wallet.find(params[:id])
  end

  sig { returns(T::Boolean) }
  def authorize_wallet_access!
    unless @wallet.user == current_api_user
      render json: { error: 'Unauthorized' }, status: :unauthorized
      return false
    end
    true
  end
end

