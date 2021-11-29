require 'rest-client'
require 'virtus'
require 'json'

class Esplora
  include Virtus.model

  API_URL = 'https://blockstream.info/testnet/api'.freeze

  attribute :address
  attribute :tx_id
  attribute :tx

  class << self
    def get_address_information(address)
      new(address: address).get_address_information
    end

    def get_utxo(address)
      new(address: address).get_utxo
    end

    def get_raw_transaction(tx_id)
      new(tx_id: tx_id).get_raw_transaction
    end

    def send_transaction(transaction)
      new(tx: transaction).send_transaction
    end
  end

  def get_address_information
    get_request("/address/#{address}")
  end

  def get_raw_transaction
    get_request("/tx/#{tx_id}/raw", raw: true)
  end

  def get_utxo
    get_request("/address/#{address}/utxo")
  end

  def send_transaction
    post_request("/tx", body: tx, raw: true)
  end

  private

  def get_request(path, raw: false)
    RestClient
      .get("#{API_URL}#{path}")
      .body
      .yield_self { |it| raw ? it : JSON.parse(it) }
  rescue RestClient::RequestFailed, JSON::ParseError => e
    puts "Something went wrong while API request — #{e.message}"
  end

  def post_request(path, body:, raw:)
    RestClient
      .post("#{API_URL}#{path}", body)
      .body
      .yield_self { |it| raw ? it : JSON.parse(it) }
  rescue RestClient::RequestFailed, JSON::ParseError => e
    puts "Something went wrong while API request — #{e.message}"
  end
end
