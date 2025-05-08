class Transaction < ApplicationRecord
  belongs_to :wallet
  belongs_to :sender, class_name: 'User', optional: true
  belongs_to :receiver, class_name: 'User', optional: true

  validates :amount, numericality: { greater_than: 0 }
end
