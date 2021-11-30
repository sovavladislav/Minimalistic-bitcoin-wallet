require 'bigdecimal'
require 'bitcoin'
require 'tempfile'
require_relative 'address_balance'
require_relative 'address_storage'

class Transaction
  include Bitcoin::Builder

  class UnexpectedError < StandardError; end

  DEFAULT_FEE = BigDecimal('0.0001')
  SATOSHI_PER_BITCOIN = BigDecimal(100000000)

  def initialize(recipient_addr, value)
    @recipient_addr = recipient_addr
    @value = BigDecimal(value)
  end

  def send
    return unless validate

    send_transaction
  rescue UnexpectedError
    puts 'Sending transaction error — try again'
  end

  private

  def actual_balance
    @actual_balance ||= AddressBalance.new(address_storage.address).get_actual || BigDecimal(0)
  end

  def address_storage
    @address_storage ||= AddressStorage.new
  end

  def bin_to_hex(s)
    s.unpack('H*').first
  end

  def build_transaction
    @build_transaction ||=
      build_tx do |t|
        input_data.each do |input|
          t.input do |i|
            i.prev_out input[:prev_out]
            i.prev_out_index input[:prev_out_index]
            i.signature_key input[:signature_key]
          end
        end

        t.output do |o|
          o.value recipient_value
          o.script {|s| s.recipient @recipient_addr }
        end

        t.output do |o|
          o.value return_value
          o.script {|s| s.recipient address_storage.address }
        end
      end
  end

  def input_data
    tx_ids.map do |tx_id|
      tx_raw = Esplora.get_raw_transaction(tx_id)
      raise UnexpectedError if tx_raw.nil?

      tempfile = Tempfile.new("transaction_#{tx_id}")
      tempfile << tx_raw
      tempfile.rewind

      prev_out = Bitcoin::P::Tx.from_file(tempfile.path)
      prev_out_indices =
        prev_out
          .out
          .each_with_index
          .reduce([]) do |res, (element, index)|
            res << index if element.parsed_script.get_address == address_storage.address
            res
          end

      prev_out_indices.map do |prev_out_index|
        {
          prev_out: prev_out,
          prev_out_index: prev_out_index,
          signature_key: signature_key,
        }
      end
    end.flatten
  end

  def private_key
    @address_storage.private_key
  end

  def public_key
    @address_storage.public_key
  end

  def recipient_value
    @value * SATOSHI_PER_BITCOIN
  end

  def return_value
    actual_balance * SATOSHI_PER_BITCOIN - @value * SATOSHI_PER_BITCOIN - DEFAULT_FEE * SATOSHI_PER_BITCOIN
  end

  def send_transaction
    body = bin_to_hex(build_transaction.to_payload)
    Esplora.send_transaction(body)
  end

  def signature_key
    @signature_key ||= Bitcoin::Key.new(private_key, public_key)
  end

  def tx_ids
    utxo = Esplora.get_utxo(address_storage.address)
    raise UnexpectedError if utxo.nil?

    utxo.map { |transaction| transaction['txid'] }
  end

  def validate
    if actual_balance < @value + DEFAULT_FEE
      puts 'Insufficient funds'
      return false
    end

    true
  end
end
