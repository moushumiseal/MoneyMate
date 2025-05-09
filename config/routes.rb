Rails.application.routes.draw do
  scope '/money_mate' do
    namespace :api do
      devise_for :users,
                 controllers: {
                   sessions: 'api/sessions'
                 },
                 defaults: { format: :json }
    end

    resources :wallets, only: [] do
      member do
        post 'deposit'
        post 'withdraw'
        post 'transfer'
      end
    end

    resources :users, only: [] do
      member do
        get 'balance'
        get 'transactions'
      end
    end
  end
end
