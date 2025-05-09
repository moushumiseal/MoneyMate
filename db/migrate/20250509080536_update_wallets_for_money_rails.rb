class UpdateWalletsForMoneyRails < ActiveRecord::Migration[6.1]
  def change
    remove_column :wallets, :balance, :decimal
    add_column :wallets, :balance_cents, :integer, default: 0, null: false
  end
end
