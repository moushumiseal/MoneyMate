MoneyRails.configure do |config|
  config.default_currency = :sgd

  # Default ActiveRecord columns configuration
  config.amount_column = { prefix: '',
                           postfix: '_cents',
                           column_name: nil,
                           type: :integer,
                           present: true,
                           null: false,
                           default: 0
  }

  config.currency_column = { prefix: '',
                             postfix: '_currency',
                             column_name: 'currency',
                             type: :string,
                             present: true,
                             null: false,
                             default: 'SGD'
  }

  # Register currency
  config.register_currency = {
    priority:            1,
    iso_code:            "SGD",
    name:                "Singapore Dollar",
    symbol:              "S$",
    symbol_first:        true,
    subunit:             "Cent",
    subunit_to_unit:     100,
    thousands_separator: ",",
    decimal_mark:        "."
  }
end

Money.rounding_mode = BigDecimal::ROUND_HALF_EVEN
Money.locale_backend = :i18n