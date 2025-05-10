class AddStatusToTransactions < ActiveRecord::Migration[7.1]
  def change
    add_column :transactions, :status, :string, default: 'pending'
    add_index :transactions, :status
  end
end
