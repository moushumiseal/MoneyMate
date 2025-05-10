# frozen_string_literal: true
# typed: true

module Api
  class UsersController < ApplicationController
    extend T::Sig

    before_action :set_user
    before_action :authorize_user_access!

    sig { void }
    def balance
      wallet_service = UserWalletService.new(@user)
      render json: wallet_service.balance_details
    end

    sig { void }
    def transactions
      page = params[:page].present? ? params[:page].to_i : 1
      per_page = params[:per_page].present? ? params[:per_page].to_i : UserTransactionService::DEFAULT_PER_PAGE

      transaction_service = UserTransactionService.new(@user)
      result = transaction_service.paginated_transactions(page: page, per_page: per_page)

      render json: result
    end

    private

    sig { void }
    def set_user
      @user = User.find(params[:id])
    end

    sig { returns(T::Boolean) }
    def authorize_user_access!
      authorization_service = UserAuthorizationService.new(@user, current_api_user)

      begin
        authorization_service.authorize!
        true
      rescue UserAuthorizationService::UnauthorizedAccessError
        render json: { error: 'Unauthorized' }, status: :unauthorized
        false
      end
    end
  end
end