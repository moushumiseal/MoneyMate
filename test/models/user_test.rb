# frozen_string_literal: true
require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "should create a wallet with zero balance after user creation" do
    user = User.create!(name: "Charlie", email: "cool_charlie@gmail.com", password: "password", password_confirmation: "password")
    assert_not_nil user.wallet
    assert_equal 0, user.wallet.balance_cents
  end

  test "can have many transactions as sender" do
    user = users(:alice)
    assert_respond_to user.wallet, :transactions
  end

  test "requires email" do
    user = User.new(name: "Charlie", password: "password", password_confirmation: "password")
    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test "should not allow invalid email format" do
    user = User.new(name: "Invalid", email: "not-an-email", password: "password", password_confirmation: "password")
    assert_not user.valid?
    assert_includes user.errors[:email], "is invalid"
  end

  test "does not allow duplicate emails" do
    User.create!(name: "John", email: "john@example.com", password: "password", password_confirmation: "password")
    duplicate_user = User.new(name: "Jonathan", email: "john@example.com", password: "password", password_confirmation: "password")
    assert_not duplicate_user.valid?
    assert_includes duplicate_user.errors[:email], "has already been taken"
  end

  test "should allow users with same name" do
    User.create!(name: "Alex", email: "alex1@example.com", password: "password", password_confirmation: "password")
    another = User.new(name: "Alex", email: "alex2@example.com", password: "password", password_confirmation: "password")
    assert another.valid?
  end

  test "should authenticate user with valid credentials" do
    user = users(:alice)
    assert user.valid_password?("password")
  end

  test "should not authenticate user with invalid credentials" do
    user = users(:alice)
    assert_not user.valid_password?("wrongpassword")
  end
end
