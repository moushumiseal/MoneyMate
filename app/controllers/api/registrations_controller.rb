# frozen_string_literal: true
# typed: true

module Api
  class RegistrationsController < Devise::RegistrationsController
    respond_to :json

    private

    def sign_up_params
      params.require(:user).permit(:email, :password, :password_confirmation, :name)
    end
  end
end

