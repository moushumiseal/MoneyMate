class AddReceiverWalletToTransactions < ActiveRecord::Migration[7.1]
  def change
    add_reference :transactions, :receiver_wallet, foreign_key: { to_table: :wallets }, null: true
    add_index :transactions, [:wallet_id, :receiver_wallet_id]
  end
end
