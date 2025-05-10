# frozen_string_literal: true
require "test_helper"

class UserAuthorizationServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:alice)
    @other_user = users(:bob)
  end

  test "authorizes when current user matches target user" do
    service = UserAuthorizationService.new(@user, @user)
    assert service.authorized?

    # Should not raise an error
    assert_nothing_raised { service.authorize! }
  end

  test "does not authorize when current user doesn't match target user" do
    service = UserAuthorizationService.new(@user, @other_user)
    assert_not service.authorized?

    # Should raise an unauthorized error
    assert_raises(UserAuthorizationService::UnauthorizedAccessError) { service.authorize! }
  end
end