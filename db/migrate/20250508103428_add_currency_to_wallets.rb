class AddCurrencyToWallets < ActiveRecord::Migration[7.1]
  def change
    add_column :wallets, :currency, :string, default: 'SGD'
  end
end
