# frozen_string_literal: true
require "test_helper"

module Api
  class UsersControllerTest < ActionDispatch::IntegrationTest
    setup do
      @user = users(:alice)
      @wallet = @user.wallet
      @auth_headers = auth_headers_for(@user)

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

    test "should return full balance JSON structure" do
      get balance_api_user_url(@user), headers: @auth_headers

      assert_response :success
      json = JSON.parse(response.body)

      assert_equal @wallet.balance.format, json["balance"]
      assert_equal @wallet.balance.to_f, json["amount_numeric"]
      assert_equal @wallet.currency, json["currency"]
    end

    test "should return full transaction list with expected structure" do
      get transactions_api_user_url(@user), headers: @auth_headers

      assert_response :success
      json = JSON.parse(response.body)

      # Check the response structure matches our expected format
      assert_includes json.keys, "transactions"
      assert_includes json.keys, "pagination"

      # Verify pagination structure
      assert_equal 1, json["pagination"]["current_page"]
      assert_includes json["pagination"].keys, "total_pages"
      assert_includes json["pagination"].keys, "total_count"

      transactions = json["transactions"]
      assert_kind_of Array, transactions
      assert_equal 2, transactions.size

      transactions.each do |txn|
        assert_includes txn.keys, "id"
        assert_includes txn.keys, "type"
        assert_includes txn.keys, "amount"
        assert_includes txn.keys, "amount_numeric"
        assert_includes txn.keys, "currency"
        assert_includes txn.keys, "sender"
        assert_includes txn.keys, "receiver"
        assert_includes txn.keys, "created_at"
        assert_includes txn.keys, "status"

        if txn["type"] == "credit"
          assert_nil txn["sender"]
          assert_equal @user.email, txn["receiver"]
        elsif txn["type"] == "debit"
          assert_equal @user.email, txn["sender"]
          assert_nil txn["receiver"]
        end

        assert_equal @frozen_time.iso8601(3), Time.zone.parse(txn["created_at"]).iso8601(3)
      end
    end

    test "should not allow unauthorized access to another user's data" do
      another_user = users(:bob)
      get balance_api_user_url(another_user), headers: @auth_headers
      assert_response :unauthorized
    end
  end
end