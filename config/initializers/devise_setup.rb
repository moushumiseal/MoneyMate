Rails.application.config.to_prepare do
  # Skip token authentication for sessions and registrations controllers
  Devise::SessionsController.skip_before_action :verify_authenticity_token, raise: false
  Devise::RegistrationsController.skip_before_action :verify_authenticity_token, raise: false

  # For API-only apps, devise controllers need special handling
  DeviseController.respond_to :json if defined?(DeviseController)
end