# frozen_string_literal: true
require "test_helper"

class UserTransactionServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:alice)
    @wallet = @user.wallet
    @service = UserTransactionService.new(@user)

    @frozen_time = Time.zone.local(2025, 5, 9, 12, 0, 0)
    Timecop.freeze(@frozen_time) do
      @wallet.transactions.create!(
        transaction_type: :credit,
        amount_cents: 1000,
        currency: "SGD",
        receiver: @user
      )

      @wallet.transactions.create!(
        transaction_type: :debit,
        amount_cents: 500,
        currency: "SGD",
        sender: @user
      )
    end
  end

  test "returns paginated transactions with correct structure" do
    result = @service.paginated_transactions(page: 1, per_page: 10)

    assert_includes result.keys, :transactions
    assert_includes result.keys, :pagination

    assert_equal 2, result[:transactions].length

    # Check pagination details
    assert_equal 1, result[:pagination][:current_page]
    assert_equal 1, result[:pagination][:total_pages]
    assert_equal 2, result[:pagination][:total_count]

    # Check transaction details
    txn = result[:transactions].first
    assert_includes txn.keys, :id
    assert_includes txn.keys, :type
    assert_includes txn.keys, :display_type
    assert_includes txn.keys, :amount
    assert_includes txn.keys, :amount_numeric
    assert_includes txn.keys, :currency
    assert_includes txn.keys, :created_at

    # Test transaction types and display types
    credit_txn = result[:transactions].find { |t| t[:type] == "credit" }
    debit_txn = result[:transactions].find { |t| t[:type] == "debit" }

    assert_equal "deposit", credit_txn[:display_type]
    assert_equal "withdraw", debit_txn[:display_type]
  end


  test "respects per_page limit" do
    result = @service.paginated_transactions(page: 1, per_page: 1)
    assert_equal 1, result[:transactions].length

    result = @service.paginated_transactions(page: 1, per_page: 150)
    assert_equal 2, result[:transactions].length
  end
end