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

  test "deposit increases balance and creates transaction" do
    amount = Money.new(100_00, 'SGD')
    assert_difference -> { @alice_wallet.transactions.count } do
      @alice_wallet.deposit(amount)
    end

    # Assert increase in balance
    assert_equal 100_00, @alice_wallet.reload.balance_cents
    txn = @alice_wallet.transactions.last
    assert_equal "deposit", txn.transaction_type
    assert_equal 100_00, txn.amount.cents
  end

  test "withdraw with sufficient balance decreases balance" do
    @alice_wallet.update!(balance_cents: 200_00)
    amount = Money.new(150_00, 'SGD')

    @alice_wallet.withdraw(amount)

    # Assert decrease in balance
    assert_equal 50_00, @alice_wallet.reload.balance_cents
    txn = @alice_wallet.transactions.last
    assert_equal "withdraw", txn.transaction_type
    assert_equal 150_00, txn.amount.cents
  end

  test "should not withdraw with insufficient balance" do
    amount = Money.new(50_00, 'SGD')
    assert_raises(StandardError, "Insufficient funds") do
      @alice_wallet.withdraw(amount)
    end
  end

  test "transfer to another wallet" do
    @alice_wallet.update!(balance_cents: 300_00)
    amount = Money.new(100_00, 'SGD')

    @alice_wallet.transfer(@bob_wallet, amount)

    assert_equal 200_00, @alice_wallet.reload.balance_cents
    assert_equal 100_00, @bob_wallet.reload.balance_cents

    txn = @alice_wallet.transactions.where(transaction_type: "transfer").last
    assert_equal @bob.id, txn.receiver_id
    assert_equal 100_00, txn.amount.cents
  end

  test "should not transfer to self" do
    amount = Money.new(50_00, 'SGD')
    assert_raises(StandardError, "Cannot transfer to self") do
      @alice_wallet.transfer(@alice_wallet, amount)
    end
  end
end
