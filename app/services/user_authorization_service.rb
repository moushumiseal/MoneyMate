# frozen_string_literal: true
# typed: true

class UserAuthorizationService
  extend T::Sig

  class UnauthorizedAccessError < StandardError; end

  sig { params(user: User, current_user: User).void }
  def initialize(user, current_user)
    @user = user
    @current_user = current_user
  end

  sig { void }
  def authorize!
    raise UnauthorizedAccessError, 'Unauthorized access to user data' unless authorized?
  end

  sig { returns(T::Boolean) }
  def authorized?
    @user == @current_user
  end
end
