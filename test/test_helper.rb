ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require 'minitest/autorun'
require 'pry'

class ActiveSupport::TestCase
  parallelize(workers: :number_of_processors)
  fixtures :all
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end
