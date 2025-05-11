# frozen_string_literal: true
# typed: true

module Api
  class SessionsController < Devise::SessionsController
    extend T::Sig


    respond_to :json

    def create
      Rails.logger.info "SessionsController#create called with params: #{params.inspect}"

      # Find user and authenticate manually
      user = User.find_by(email: params.dig(:user, :email))

      unless user
        Rails.logger.info "User not found with email: #{params.dig(:user, :email)}"
        return render json: { error: "Invalid email or password" }, status: :unauthorized
      end

      unless user.valid_password?(params.dig(:user, :password))
        Rails.logger.info "Invalid password for user: #{user.email}"
        return render json: { error: "Invalid email or password" }, status: :unauthorized
      end

      # If we get here, credentials are valid
      Rails.logger.info "Credentials valid for user: #{user.email}"

      # Manually sign in the user
      sign_in user

      # Return success response
      render json: {
        message: "Logged in successfully",
        user: {
          id: user.id,
          email: user.email
        }
      }, status: :ok
    end

    private

    def respond_with(resource, _opts = {})
      render json: { message: 'Logged in.', user: resource }, status: :ok
    end

    def respond_to_on_destroy
      render json: { message: 'Logged out.' }, status: :ok
    end
  end
end