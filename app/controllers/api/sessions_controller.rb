# frozen_string_literal: true
# typed: true

module Api
  class SessionsController < Devise::SessionsController
    extend T::Sig

    respond_to :json

    # Skip CSRF protection for API
    skip_before_action :verify_authenticity_token

    private

    sig { returns(Hash) }
    def respond_with(resource, _opts = {})
      render json: {
        status: { code: 200, message: 'Logged in successfully' },
        data: {
          user: {
            id: resource.id,
            email: resource.email
          }
        }
      }
    end

    sig { returns(Hash) }
    def respond_to_on_destroy
      if current_user
        render json: {
          status: 200,
          message: 'Logged out successfully'
        }
      else
        render json: {
          status: 401,
          message: 'Couldn\'t find an active session.'
        }
      end
    end
  end
end

