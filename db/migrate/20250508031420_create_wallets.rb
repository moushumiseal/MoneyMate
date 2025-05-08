class CreateWallets < ActiveRecord::Migration[7.1]
  def change
    create_table :wallets do |t|
      t.decimal :balance, precision: 15, scale: 2
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
