ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require 'minitest/autorun'
require 'pry'
require 'devise/jwt/test_helpers'
require "timecop"


class ActiveSupport::TestCase
  parallelize(workers: :number_of_processors)
  fixtures :all

  # Helper method to generate JWT auth headers
  def auth_headers_for(user)
    headers = { 'Accept' => 'application/json', 'Content-Type' => 'application/json' }
    Devise::JWT::TestHelpers.auth_headers(headers, user)
  end
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end
