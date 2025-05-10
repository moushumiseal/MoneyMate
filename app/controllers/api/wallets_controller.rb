# frozen_string_literal: true
# typed: true

module Api
  class WalletsController < ApplicationController
    extend T::Sig

    before_action :set_wallet
    before_action :authorize_wallet_access!

    sig { void }
    def deposit
      amount = Money.from_amount(params[:amount].to_f, 'SGD')

      begin
        WalletService.deposit(@wallet, amount)
        render json: wallet_json
      rescue ArgumentError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end
    end

    sig { void }
    def withdraw
      amount = Money.from_amount(params[:amount].to_f, 'SGD')

      begin
        WalletService.withdraw(@wallet, amount)
        render json: wallet_json
      rescue WalletService::InsufficientFundsError, ArgumentError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end
    end

    sig { void }
    def transfer
      receiver = User.find(params[:receiver_id])
      amount = Money.from_amount(params[:amount].to_f, 'SGD')

      begin
        WalletService.transfer(@wallet, receiver.wallet, amount)
        render json: wallet_json
      rescue WalletService::InsufficientFundsError, WalletService::InvalidTransactionError, ArgumentError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end
    end

    private

    sig { returns(T::Hash[Symbol, T.any(String, Float)]) }
    def wallet_json
      {
        balance: @wallet.balance.format,
        amount_numeric: @wallet.balance.to_f,
        currency: @wallet.currency
      }
    end

    sig { void }
    def set_wallet
      @wallet = Wallet.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Wallet not found' }, status: :not_found
    end

    sig { returns(T::Boolean) }
    def authorize_wallet_access!
      unless @wallet.user == current_api_user
        render json: { error: "You don't have access to this wallet" }, status: :unauthorized
        return false
      end
      true
    end
  end
end