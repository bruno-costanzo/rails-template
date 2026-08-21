require "test_helper"

class MoneyConfigurationTest < ActiveSupport::TestCase
  test "defaults to USD" do
    assert_equal "USD", Money.default_currency.iso_code
  end

  test "formats amounts as USD" do
    assert_equal "$19.99", Money.from_amount(19.99).format
  end
end
