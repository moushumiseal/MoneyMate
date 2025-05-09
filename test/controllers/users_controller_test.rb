# frozen_string_literal: true
require "test_helper"

require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:alice)
    @wallet = @user.wallet
  end

  test "should return balance" do
    get balance_user_url(@user)
    assert_response :success
    assert_includes JSON.parse(response.body), "balance"
  end

  test "should return transactions" do
    @wallet.transactions.create!(transaction_type: :deposit, amount: 50.0, wallet: @wallet)
    get transactions_user_url(@user)
    assert_response :success
    assert_kind_of Array, JSON.parse(response.body)
  end
end
