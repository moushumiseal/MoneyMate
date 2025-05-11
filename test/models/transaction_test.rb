# frozen_string_literal: true
require "test_helper"

class TransactionTest < ActiveSupport::TestCase
  test "should belong to a wallet" do
    transaction = Transaction.new(
      transaction_type: :credit,
      amount_cents: 100_00,
      currency: "SGD",
      receiver: users(:alice)
    )
    assert_not transaction.valid?
    assert_includes transaction.errors[:wallet], "must exist"
  end

  test "enum transaction_type includes expected values" do
    assert_includes Transaction.transaction_types.keys, "credit"
    assert_includes Transaction.transaction_types.keys, "debit"
  end

  test "enum status includes expected values" do
    assert_includes Transaction.statuses.keys, "pending"
    assert_includes Transaction.statuses.keys, "completed"
    assert_includes Transaction.statuses.keys, "failed"
    assert_includes Transaction.statuses.keys, "cancelled"
  end
end