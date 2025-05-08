class CreateTransactions < ActiveRecord::Migration[7.1]
  def change
    create_table :transactions do |t|
      t.string :transaction_type
      t.decimal :amount, precision: 15, scale: 2
      t.integer :sender_id
      t.integer :receiver_id
      t.references :wallet, null: false, foreign_key: true

      t.timestamps
    end
  end
end
