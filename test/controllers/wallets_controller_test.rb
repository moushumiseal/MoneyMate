# frozen_string_literal: true
require "test_helper"

class WalletsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:alice)
    @wallet = @user.wallet

    # User Sign in by stubbing Devise
    sign_in @user
  end

  test "should deposit money" do
    post deposit_wallet_url(@wallet), params: { amount_cents: 100_00, currency: "SGD" }
    assert_response :success
    assert_equal 100_00, @wallet.reload.balance_cents
  end

  test "should withdraw money if sufficient balance" do
    @wallet.update!(balance_cents: 200_00)
    post withdraw_wallet_url(@wallet), params: { amount_cents: 100_00, currency: "SGD" }
    assert_response :success
    assert_equal 100_00, @wallet.reload.balance_cents
  end

  test "should not withdraw money if insufficient balance" do
    post withdraw_wallet_url(@wallet), params: { amount_cents: 200_00, currency: "SGD" }
    assert_response :unprocessable_entity
  end

  test "should transfer money" do
    bob = users(:bob)
    @wallet.update!(balance_cents: 300_00)

    post transfer_wallet_url(@wallet), params: { receiver_id: bob.id, amount_cents: 150_00, currency: "SGD" }
    assert_response :success
    assert_equal 150_00, @wallet.reload.balance_cents
    assert_equal 150_00, bob.wallet.reload.balance_cents
  end
end
