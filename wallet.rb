require_relative 'lib/address_storage'
require_relative 'lib/address_balance'
require_relative 'lib/transaction'

Bitcoin.network = :testnet
address_storage = AddressStorage.new
useful_tip = "Type 'help' for a list of commands"

puts "Your Bitcoin testnet address — #{address_storage.address}"
puts useful_tip

while (command = gets.chomp) != 'exit'
  case command
  when 'address'
    puts address_storage.address
  when 'balance'
    balance = AddressBalance.new(address_storage.address).get_actual
    puts balance.to_f if balance
  when /send (tb1|[2nm]|bcrt)[a-zA-HJ-NP-Z0-9]{25,40} (\d+(?:\.\d+)?)/
    _, recipient_addr, value = command.split(' ')
    result = Transaction.new(recipient_addr, value).send
    puts 'Transaction sent successfully' if result
  when 'help'
    string = <<-STRING
      address – shows generated address
      balance — shows balance of funds on generated address
      help — shows list of commands
      send ADDR amount — sends a specified amount of funds to address that user specified
      exit — terminates program
    STRING
    puts string
  when 'exit'
    break
  else
    puts useful_tip
  end
end
