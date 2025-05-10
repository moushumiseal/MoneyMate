# frozen_string_literal: true
require "test_helper"

class TransactionTest < ActiveSupport::TestCase
  test "should belong to a wallet" do
    transaction = Transaction.new(
      transaction_type: :deposit,
      amount_cents: 100_00,
      currency: "SGD",
      receiver: users(:alice)  # Add receiver for deposit
    )
    assert_not transaction.valid?
    assert_includes transaction.errors[:wallet], "must exist"
  end

  test "transfer should include sender and receiver" do
    transaction = Transaction.new(
      transaction_type: "transfer",
      amount_cents: 75_00,
      currency: "SGD",
      wallet: wallets(:alice_wallet),
      sender: users(:alice),
      receiver: users(:bob),
      receiver_wallet: wallets(:bob_wallet)  # Add receiver_wallet for transfer
    )
    assert transaction.valid?
  end

  test "enum transaction_type includes expected values" do
    assert_includes Transaction.transaction_types.keys, "deposit"
    assert_includes Transaction.transaction_types.keys, "withdraw"
    assert_includes Transaction.transaction_types.keys, "transfer"
  end

  test "can create a deposit transaction" do
    transaction = Transaction.new(
      transaction_type: "deposit",
      amount_cents: 100_00,
      currency: "SGD",
      wallet: wallets(:alice_wallet),
      receiver: users(:alice)  # Add receiver for deposit
    )
    assert transaction.valid?
  end
end