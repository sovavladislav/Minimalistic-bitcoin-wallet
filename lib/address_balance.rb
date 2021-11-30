require 'bigdecimal'
require_relative 'esplora'

class AddressBalance
  SATOSHI_PER_BITCOIN = BigDecimal(100000000)

  attr_reader :address

  def initialize(address)
    @address = address
  end

  def get_actual
    address_information = Esplora.get_address_information(address)
    return if address_information.nil?

    chain_sub = substitute(address_information, 'chain_stats')
    mempool_sub = substitute(address_information, 'mempool_stats')

    BigDecimal(chain_sub + mempool_sub) / SATOSHI_PER_BITCOIN
  end

  private

  def substitute(parsed_body, key)
    parsed_body[key]['funded_txo_sum'] - parsed_body[key]['spent_txo_sum']
  end
end
