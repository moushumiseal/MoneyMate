# frozen_string_literal: true
# typed: true

class UserTransactionService
  extend T::Sig

  DEFAULT_PER_PAGE = 10
  MAX_PER_PAGE = 100

  sig { params(user: User).void }
  def initialize(user)
    @user = user
  end

  sig { params(page: Integer, per_page: Integer).returns(Hash) }
  def paginated_transactions(page: 1, per_page: DEFAULT_PER_PAGE)
    per_page = [[per_page.to_i, 1].max, MAX_PER_PAGE].min

    # Use page 1 if page is less than 1
    page = [page.to_i, 1].max

    # Fetch transactions with pagination
    transactions = @user.wallet.transactions.order(created_at: :desc).page(page).per(per_page)

    {
      transactions: serialize_transactions(transactions),
      pagination: {
        current_page: transactions.current_page,
        total_pages: transactions.total_pages,
        total_count: transactions.total_count,
      }
    }
  end

  private

  sig { params(transactions: ActiveRecord::Relation).returns(T::Array[Hash]) }
  def serialize_transactions(transactions)
    transactions.map do |txn|
      {
        id: txn.id,
        type: txn.transaction_type,
        amount: txn.amount.format,
        amount_numeric: txn.amount.to_f,
        currency: txn.currency,
        sender: txn.sender&.email,
        receiver: txn.receiver&.email,
        created_at: txn.created_at,
        status: txn.status,
      }
    end
  end
end
