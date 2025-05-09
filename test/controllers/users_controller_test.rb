# frozen_string_literal: true
require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:alice)
    @wallet = @user.wallet

    @frozen_time = Time.zone.local(2025, 5, 9, 12, 0, 0)
    Timecop.freeze(@frozen_time) do
      @wallet.transactions.create!(
        transaction_type: :deposit,
        amount_cents: 1000,
        currency: "SGD"
      )

      @wallet.transactions.create!(
        transaction_type: :withdraw,
        amount_cents: 500,
        currency: "SGD"
      )
    end

    sign_in @user
  end

  test "should return full balance JSON structure" do
    get balance_user_url(@user), headers: @auth_headers

    assert_response :success
    json = JSON.parse(response.body)

    assert_equal @wallet.balance.format, json["balance"]
    assert_equal @wallet.balance.to_f, json["amount_numeric"]
    assert_equal @wallet.currency, json["currency"]
  end

  test "should return full transaction list with expected structure" do
    get transactions_user_url(@user), headers: @auth_headers

    assert_response :success
    json = JSON.parse(response.body)

    assert_kind_of Array, json
    assert_equal 2, json.size

    json.each do |txn|
      assert_includes txn.keys, "id"
      assert_includes txn.keys, "type"
      assert_includes txn.keys, "amount"
      assert_includes txn.keys, "amount_numeric"
      assert_includes txn.keys, "currency"
      assert_includes txn.keys, "sender"
      assert_includes txn.keys, "receiver"
      assert_includes txn.keys, "created_at"

      assert_nil txn["sender"]
      assert_nil txn["receiver"]
      assert_equal @frozen_time.iso8601(3), Time.zone.parse(txn["created_at"]).iso8601(3)
    end
  end
end
