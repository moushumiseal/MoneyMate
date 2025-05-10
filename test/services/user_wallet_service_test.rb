# frozen_string_literal: true
require "test_helper"

class UserWalletServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:alice)
    @service = UserWalletService.new(@user)
  end

  test "returns correct balance details" do
    details = @service.balance_details

    assert_equal @user.wallet.balance.format, details[:balance]
    assert_equal @user.wallet.balance.to_f, details[:amount_numeric]
    assert_equal @user.wallet.currency, details[:currency]
  end
end