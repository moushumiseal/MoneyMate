# frozen_string_literal: true
require "test_helper"

class WalletsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:alice)
    @wallet = @user.wallet
    sign_in @user
  end

  test "should deposit money" do
    # Make sure the amount is greater than 0
    post deposit_wallet_url(@wallet), params: { amount: 100.0 }
    assert_response :success
    assert_equal 100.0, @wallet.reload.balance.to_f
  end

  test "should withdraw money if sufficient balance" do
    @wallet.update!(balance: 200.0)
    post withdraw_wallet_url(@wallet), params: { amount: 100.0 }
    assert_response :success
    assert_equal 100.0, @wallet.reload.balance.to_f
  end

  test "should not withdraw money if insufficient balance" do
    post withdraw_wallet_url(@wallet), params: { amount: 200.0 }
    assert_response :unprocessable_entity
  end

  test "should transfer money" do
    bob = users(:bob)
    @wallet.update!(balance: 300.0)

    post transfer_wallet_url(@wallet), params: { receiver_id: bob.id, amount: 150.0 }
    assert_response :success
    assert_equal 150.0, @wallet.reload.balance.to_f
    assert_equal 150.0, bob.wallet.reload.balance.to_f
  end
end
