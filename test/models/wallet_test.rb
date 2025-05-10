# frozen_string_literal: true

require "test_helper"

class WalletTest < ActiveSupport::TestCase
  setup do
    @alice = users(:alice)
    @bob = users(:bob)
    @alice_wallet = @alice.wallet
    @bob_wallet = @bob.wallet
  end

  test "should belong to a user" do
    wallet = wallets(:alice_wallet)
    assert_equal @alice, wallet.user
  end

  test "should not allow negative balance" do
    wallet = Wallet.new(user: @alice, balance_cents: -1000, currency: "SGD")
    assert_not wallet.valid?
    assert_includes wallet.errors[:balance], "must be greater than or equal to 0"
  end

  test "should have default currency as SGD" do
    assert_equal 'SGD', @alice_wallet.currency
  end

  test "has many transactions" do
    assert_respond_to @alice_wallet, :transactions
  end

  test "should maintain proper currency" do
    assert_includes Wallet::SUPPORTED_CURRENCIES, @alice_wallet.currency
  end
end
