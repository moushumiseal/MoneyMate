# frozen_string_literal: true
require "test_helper"

class WalletServiceTest < ActiveSupport::TestCase
  setup do
    @alice = users(:alice)
    @bob = users(:bob)
    @alice_wallet = @alice.wallet
    @bob_wallet = @bob.wallet

    # Reset wallet balances
    @alice_wallet.update!(balance_cents: 0)
    @bob_wallet.update!(balance_cents: 0)
  end

  test "deposit adds money to wallet" do
    assert_difference -> { @alice_wallet.reload.balance_cents }, 5000 do
      WalletService.deposit(@alice_wallet, Money.new(5000, 'SGD'))
    end

    assert_equal Money.new(5000, 'SGD'), @alice_wallet.reload.balance
  end

  test "deposit creates a transaction record" do
    assert_difference -> { Transaction.count }, 1 do
      WalletService.deposit(@alice_wallet, Money.new(5000, 'SGD'))
    end

    transaction = Transaction.last
    assert_equal 'credit', transaction.transaction_type
    assert_equal 5000, transaction.amount_cents
    assert_equal @alice.id, transaction.receiver_id
    assert_nil transaction.sender_id
    assert_equal 'SGD', transaction.currency
  end

  test "deposit with negative amount raises error" do
    assert_no_difference -> { @alice_wallet.reload.balance_cents } do
      assert_raises(ArgumentError) do
        WalletService.deposit(@alice_wallet, Money.new(-1000, 'SGD'))
      end
    end
  end

  test "deposit with zero amount raises error" do
    assert_no_difference -> { @alice_wallet.reload.balance_cents } do
      assert_raises(ArgumentError) do
        WalletService.deposit(@alice_wallet, Money.new(0, 'SGD'))
      end
    end
  end

  test "multiple deposits accumulate correctly" do
    WalletService.deposit(@alice_wallet, Money.new(5000, 'SGD'))
    WalletService.deposit(@alice_wallet, Money.new(3000, 'SGD'))
    WalletService.deposit(@alice_wallet, Money.new(2000, 'SGD'))

    assert_equal Money.new(10000, 'SGD'), @alice_wallet.reload.balance
  end

  test "withdraw removes money from wallet" do
    WalletService.deposit(@alice_wallet, Money.new(10000, 'SGD'))

    assert_difference -> { @alice_wallet.reload.balance_cents }, -3000 do
      WalletService.withdraw(@alice_wallet, Money.new(3000, 'SGD'))
    end

    assert_equal Money.new(7000, 'SGD'), @alice_wallet.reload.balance
  end

  test "withdraw creates a transaction record" do
    WalletService.deposit(@alice_wallet, Money.new(10000, 'SGD'))

    assert_difference -> { Transaction.count }, 1 do
      WalletService.withdraw(@alice_wallet, Money.new(3000, 'SGD'))
    end

    transaction = Transaction.last
    assert_equal 'debit', transaction.transaction_type
    assert_equal 3000, transaction.amount_cents
    assert_equal @alice.id, transaction.sender_id
    assert_nil transaction.receiver_id
    assert_equal 'SGD', transaction.currency
  end

  test "withdraw with negative amount raises error" do
    WalletService.deposit(@alice_wallet, Money.new(10000, 'SGD'))

    assert_no_difference -> { @alice_wallet.reload.balance_cents } do
      assert_raises(ArgumentError) do
        WalletService.withdraw(@alice_wallet, Money.new(-1000, 'SGD'))
      end
    end
  end

  test "withdraw with zero amount raises error" do
    WalletService.deposit(@alice_wallet, Money.new(10000, 'SGD'))

    assert_no_difference -> { @alice_wallet.reload.balance_cents } do
      assert_raises(ArgumentError) do
        WalletService.withdraw(@alice_wallet, Money.new(0, 'SGD'))
      end
    end
  end

  test "withdraw more than balance raises InsufficientFundsError" do
    WalletService.deposit(@alice_wallet, Money.new(5000, 'SGD'))

    assert_no_difference -> { @alice_wallet.reload.balance_cents } do
      assert_raises(WalletService::InsufficientFundsError) do
        WalletService.withdraw(@alice_wallet, Money.new(6000, 'SGD'))
      end
    end
  end

  test "withdraw exact balance is allowed" do
    WalletService.deposit(@alice_wallet, Money.new(5000, 'SGD'))

    assert_difference -> { @alice_wallet.reload.balance_cents }, -5000 do
      WalletService.withdraw(@alice_wallet, Money.new(5000, 'SGD'))
    end

    assert_equal Money.new(0, 'SGD'), @alice_wallet.reload.balance
  end

  test "transfer moves money between wallets" do
    WalletService.deposit(@alice_wallet, Money.new(10000, 'SGD'))

    assert_difference -> { @alice_wallet.reload.balance_cents }, -3000 do
      assert_difference -> { @bob_wallet.reload.balance_cents }, 3000 do
        WalletService.transfer(@alice_wallet, @bob_wallet, Money.new(3000, 'SGD'))
      end
    end

    assert_equal Money.new(7000, 'SGD'), @alice_wallet.reload.balance
    assert_equal Money.new(3000, 'SGD'), @bob_wallet.reload.balance
  end

  test "transfer creates two transaction records" do
    WalletService.deposit(@alice_wallet, Money.new(10000, 'SGD'))

    assert_difference -> { Transaction.count }, 2 do
      WalletService.transfer(@alice_wallet, @bob_wallet, Money.new(3000, 'SGD'))
    end

    # Check debit transaction (sender's side)
    debit_txn = Transaction.where(transaction_type: 'debit').last
    assert_equal 'debit', debit_txn.transaction_type
    assert_equal 3000, debit_txn.amount_cents
    assert_equal @alice.id, debit_txn.sender_id
    assert_equal @bob.id, debit_txn.receiver_id
    assert_equal @bob_wallet.id, debit_txn.receiver_wallet_id
    assert_equal 'SGD', debit_txn.currency
    assert_equal @alice_wallet.id, debit_txn.wallet_id

    # Check credit transaction (receiver's side)
    credit_txn = Transaction.where(transaction_type: 'credit').last
    assert_equal 'credit', credit_txn.transaction_type
    assert_equal 3000, credit_txn.amount_cents
    assert_equal @alice.id, credit_txn.sender_id
    assert_equal @bob.id, credit_txn.receiver_id
    assert_equal @alice_wallet.id, credit_txn.receiver_wallet_id
    assert_equal 'SGD', credit_txn.currency
    assert_equal @bob_wallet.id, credit_txn.wallet_id
  end

  test "transfer with negative amount raises error" do
    WalletService.deposit(@alice_wallet, Money.new(10000, 'SGD'))

    assert_no_difference -> { @alice_wallet.reload.balance_cents } do
      assert_no_difference -> { @bob_wallet.reload.balance_cents } do
        assert_raises(ArgumentError) do
          WalletService.transfer(@alice_wallet, @bob_wallet, Money.new(-1000, 'SGD'))
        end
      end
    end
  end

  test "transfer with zero amount raises error" do
    WalletService.deposit(@alice_wallet, Money.new(10000, 'SGD'))

    assert_no_difference -> { @alice_wallet.reload.balance_cents } do
      assert_no_difference -> { @bob_wallet.reload.balance_cents } do
        assert_raises(ArgumentError) do
          WalletService.transfer(@alice_wallet, @bob_wallet, Money.new(0, 'SGD'))
        end
      end
    end
  end

  test "transfer more than balance raises InsufficientFundsError" do
    WalletService.deposit(@alice_wallet, Money.new(5000, 'SGD'))

    assert_no_difference -> { @alice_wallet.reload.balance_cents } do
      assert_no_difference -> { @bob_wallet.reload.balance_cents } do
        assert_raises(WalletService::InsufficientFundsError) do
          WalletService.transfer(@alice_wallet, @bob_wallet, Money.new(6000, 'SGD'))
        end
      end
    end
  end

  test "transfer to self raises InvalidTransactionError" do
    WalletService.deposit(@alice_wallet, Money.new(5000, 'SGD'))

    assert_no_difference -> { @alice_wallet.reload.balance_cents } do
      assert_raises(WalletService::InvalidTransactionError) do
        WalletService.transfer(@alice_wallet, @alice_wallet, Money.new(1000, 'SGD'))
      end
    end
  end

  test "transfer is atomic - fails completely if part fails" do
    mock_wallet = Minitest::Mock.new
    def mock_wallet.with_lock; yield; end
    def mock_wallet.save!; raise StandardError, "Simulated failure"; end
    def mock_wallet.balance; Money.new(0, 'SGD'); end
    def mock_wallet.balance=(_); end
    def mock_wallet.==(_); false; end

    WalletService.deposit(@alice_wallet, Money.new(5000, 'SGD'))
    original_balance = @alice_wallet.reload.balance

    # Attempt transfer that will fail during the deposit step
    assert_raises(StandardError) do
      WalletService.transfer(@alice_wallet, mock_wallet, Money.new(1000, 'SGD'))
    end

    # Verify nothing changed. Transaction was rolled back
    assert_equal original_balance, @alice_wallet.reload.balance
  end

  test "concurrent transfers don't exceed balance" do
    @alice_wallet.update!(balance_cents: 0)
    @bob_wallet.update!(balance_cents: 0)

    WalletService.deposit(@alice_wallet, Money.new(10000, 'SGD'))
    @alice_wallet.reload
    @bob_wallet.reload

    initial_total = @alice_wallet.balance + @bob_wallet.balance

    # Simulating concurrent transfers by creating threads
    threads = []
    5.times do
      threads << Thread.new do
        # Each thread tries to transfer 3000 cents
        begin
          WalletService.transfer(@alice_wallet, @bob_wallet, Money.new(3000, 'SGD'))
        rescue WalletService::InsufficientFundsError
          # Expected for some threads
        end
      end
    end

    # Wait for all threads to complete
    threads.each(&:join)

    # Checking that final balances are not negative
    assert @alice_wallet.reload.balance >= Money.new(0, 'SGD')

    # Making sure that total money in system is preserved
    final_total = @alice_wallet.reload.balance + @bob_wallet.reload.balance
    assert_equal initial_total, final_total,
                 "Money was created or destroyed: started with #{initial_total.format}, ended with #{final_total.format}"
  end
end