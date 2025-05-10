# frozen_string_literal: true
require "test_helper"

module Api
  class WalletsControllerTest < ActionDispatch::IntegrationTest
    setup do
      @user = users(:alice)
      @wallet = @user.wallet
      @headers = auth_headers_for(@user)
    end

    test "should deposit money" do
      post deposit_api_wallet_url(@wallet),
           params: { amount: 100.0 },
           headers: @headers,
           as: :json
      assert_response :success
      assert_equal 100.0, @wallet.reload.balance.to_f

      json = JSON.parse(response.body)
      assert_equal "S$100.00", json["balance"]
      assert_equal 100.0, json["amount_numeric"]
      assert_equal "SGD", json["currency"]
    end

    test "should not allow deposit of negative amounts" do
      post deposit_api_wallet_url(@wallet),
           params: { amount: -50.0 },
           headers: @headers,
           as: :json
      assert_response :unprocessable_entity
      assert_equal 0.0, @wallet.reload.balance.to_f
      json = JSON.parse(response.body)
      assert_includes json["error"], "Amount must be positive"
    end

    test "should withdraw money if sufficient balance" do
      WalletService.deposit(@wallet, Money.new(200_00, 'SGD'))

      post withdraw_api_wallet_url(@wallet),
           params: { amount: 100.0 },
           headers: @headers,
           as: :json
      assert_response :success
      assert_equal 100.0, @wallet.reload.balance.to_f

      json = JSON.parse(response.body)
      assert_equal "S$100.00", json["balance"]
    end

    test "should not withdraw money if insufficient balance" do
      post withdraw_api_wallet_url(@wallet),
           params: { amount: 200.0 },
           headers: @headers,
           as: :json
      assert_response :unprocessable_entity
      json = JSON.parse(response.body)
      assert_includes json["error"], "Insufficient funds"
    end

    test "should transfer money" do
      bob = users(:bob)
      WalletService.deposit(@wallet, Money.new(300_00, 'SGD'))

      post transfer_api_wallet_url(@wallet),
           params: { receiver_id: bob.id, amount: 150.0 },
           headers: @headers,
           as: :json
      assert_response :success
      assert_equal 150.0, @wallet.reload.balance.to_f
      assert_equal 150.0, bob.wallet.reload.balance.to_f

      # Check transaction was created correctly
      txn = @wallet.transactions.where(transaction_type: "transfer").last
      assert_equal @user.id, txn.sender_id
      assert_equal bob.id, txn.receiver_id
      assert_equal bob.wallet.id, txn.receiver_wallet_id
      assert_equal 150_00, txn.amount_cents
    end

    test "should not allow unauthorized access to another user's wallet" do
      another_user = users(:bob)
      headers = auth_headers_for(another_user)

      post deposit_api_wallet_url(@wallet),
           params: { amount: 50.0 },
           headers: headers,
           as: :json
      assert_response :unauthorized

      post withdraw_api_wallet_url(@wallet),
           params: { amount: 50.0 },
           headers: headers,
           as: :json
      assert_response :unauthorized

      post transfer_api_wallet_url(@wallet),
           params: { receiver_id: another_user.id, amount: 50.0 },
           headers: headers,
           as: :json
      assert_response :unauthorized
    end

    test "should return not found when wallet doesn't exist" do
      non_existent_id = 999999
      post deposit_api_wallet_url(non_existent_id),
           params: { amount: 10.0 },
           headers: @headers,
           as: :json
      assert_response :not_found

      json = JSON.parse(response.body)
      assert_equal "Wallet not found", json["error"]
    end

    test "should not transfer to self" do
      WalletService.deposit(@wallet, Money.new(100_00, 'SGD'))

      post transfer_api_wallet_url(@wallet),
           params: { receiver_id: @user.id, amount: 50.0 },
           headers: @headers,
           as: :json
      assert_response :unprocessable_entity

      json = JSON.parse(response.body)
      assert_includes json["error"], "Cannot transfer to self"
    end
  end
end