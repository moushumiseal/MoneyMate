class UpdateTransactionsForMoneyRails < ActiveRecord::Migration[6.1]
  def change
    remove_column :transactions, :amount, :decimal
    add_column :transactions, :amount_cents, :integer, default: 0, null: false
  end
end
