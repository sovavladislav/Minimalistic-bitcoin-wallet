require 'bitcoin'
require 'ecdsa'

class AddressStorage
  attr_accessor :private_key
  attr_accessor :public_key
  attr_accessor :address

  ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
  COMPRESSED_EVEN_PREFIX = "\x02"
  COMPRESSED_ODD_PREFIX = "\x03"
  COMPRESSION_FLAG = "\x01".b
  PRIVATE_KEY_VERSION = "\xef".b
  PUBLIC_KEY_VERSION = "\x6f"

  def initialize
    load_private_key_and_restore || generate_new_address
  end

  private

  def checksum(key)
    first_sha = Digest::SHA256.digest(key)
    second_sha = Digest::SHA256.digest(first_sha)
    second_sha[0...4]
  end

  # bitcoin-ruby implementation
  def encode_base58(hex)
    hex_val = hex.unpack("H*")[0]
    leading_zero_bytes  = (hex_val.match(/^([0]+)/) ? $1 : '').size / 2
    int_val = hex_val.to_i(16)
    base58_val, base = '', ALPHABET.size
    while int_val.positive?
      int_val, remainder = int_val.divmod(base)
      base58_val = ALPHABET[remainder] + base58_val
    end
    ("1" * leading_zero_bytes) + base58_val
  end

  def generate_and_save_private_key
    generate_private_key

    private_key_with_version = PRIVATE_KEY_VERSION + private_key + COMPRESSION_FLAG
    private_key_with_checksum = private_key_with_version + checksum(private_key_with_version)
    encoded_key = encode_base58(private_key_with_checksum)

    File.open('private_key', 'w') { |file| file.write(encoded_key) }
  end

  def generate_address
    public_key_sha256 = Digest::SHA256.digest(public_key)
    public_key_hash = Digest::RMD160.digest(public_key_sha256)

    public_key_with_version = PUBLIC_KEY_VERSION + public_key_hash 
    public_key_with_checksum = public_key_with_version + checksum(public_key_with_version)

    @address = encode_base58(public_key_with_checksum)
  end

  def generate_new_address
    generate_and_save_private_key
    generate_public_key
    generate_address 
  end

  def generate_private_key
    @private_key ||= SecureRandom.hex(16)
  end

  def generate_public_key
    @public_key = public_key_prefix + [public_key_point.x.to_s(16)].pack("H*")
  end

  def load_private_key_and_restore
    return false unless File.exist?('private_key')

    base58_key = File.open('private_key').read
    decrypted_key = Bitcoin::Key.from_base58(base58_key)

    @private_key = decrypted_key.priv
    @public_key = decrypted_key.pub
    @address = decrypted_key.addr
  rescue RuntimeError => e
    puts "An error while loading private key - #{e.message}"
    false
  end

  def public_key_point
    @public_key_point ||=
      ECDSA::Group::Secp256k1
        .generator
        .multiply_by_scalar(private_key.unpack("H*")[0].to_i(16))
  end

  def public_key_prefix
    public_key_point.y % 2 == 0 ? COMPRESSED_EVEN_PREFIX : COMPRESSED_ODD_PREFIX
  end

  def sha256(hex)
    Digest::SHA256.digest(hex)
  end
end
