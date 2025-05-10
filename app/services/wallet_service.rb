# frozen_string_literal: true
# typed: true

class WalletService
  extend T::Sig

  class InsufficientFundsError < StandardError; end
  class InvalidTransactionError < StandardError; end

  sig { params(wallet: Wallet, amount: Money).void }
  def self.deposit(wallet, amount)
    raise ArgumentError, 'Amount must be positive' if amount <= Money.new(0, amount.currency)

    wallet.with_lock do
      wallet.balance += amount
      wallet.save!
      wallet.transactions.create!(
        amount_cents: amount.cents,
        transaction_type: :deposit,
        sender: nil,
        receiver: wallet.user,
        currency: wallet.currency,
        status: :completed,
      )
    end
  end

  sig { params(wallet: Wallet, amount: Money).void }
  def self.withdraw(wallet, amount)
    raise ArgumentError, 'Amount must be positive' if amount <= Money.new(0, amount.currency)

    wallet.with_lock do
      raise InsufficientFundsError, "Insufficient funds (needed: #{amount.format}, available: #{wallet.balance.format})" if wallet.balance < amount

      wallet.balance -= amount
      wallet.save!
      wallet.transactions.create!(
        amount_cents: amount.cents,
        transaction_type: :withdraw,
        sender: wallet.user,
        receiver: nil,
        currency: wallet.currency,
        status: :completed,
      )
    end
  end

  sig { params(from_wallet: Wallet, to_wallet: Wallet, amount: Money).void }
  def self.transfer(from_wallet, to_wallet, amount)
    raise ArgumentError, 'Amount must be positive' if amount <= Money.new(0, amount.currency)
    raise InvalidTransactionError, 'Cannot transfer to self' if from_wallet == to_wallet

    # Locking both wallets to prevent deadlocks
    first_wallet, second_wallet = [from_wallet, to_wallet].sort_by(&:id)

    ApplicationRecord.transaction do
      first_wallet.with_lock do
        second_wallet.with_lock do
          if from_wallet.balance < amount
            raise InsufficientFundsError, "Insufficient funds (needed: #{amount.format}, available: #{from_wallet.balance.format})"
          end

          from_wallet.balance -= amount
          from_wallet.save!

          to_wallet.balance += amount
          to_wallet.save!

          from_wallet.transactions.create!(
            amount_cents: amount.cents,
            transaction_type: :transfer,
            sender: from_wallet.user,
            receiver: to_wallet.user,
            receiver_wallet: to_wallet,
            currency: from_wallet.currency,
            status: :completed,
          )
        end
      end
    end
  end
end