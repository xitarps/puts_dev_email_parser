require 'net/imap'

class Imap
  IMAP_SERVER = 'imap.gmail.com'
  IMAP_PORT = 993
  EMAIL_ADDRESS = 'seu_email@gmail.com'
  PASSWORD = ENV['GMAIL_APP_PASSWORD'] # 'senha'

  attr_reader :connection

  def initialize
    @connection = Net::IMAP.new(IMAP_SERVER, port: IMAP_PORT, ssl: true)
    self
  end

  def login
    begin
      puts "Connecting to #{IMAP_SERVER}"
      connection.login(EMAIL_ADDRESS, PASSWORD)
      puts "Login successful"
    rescue Net::IMAP::Error => e
      puts "IMAP Error: could not connect or authenticate, Check credentials: #{e.message}"
      shutdown
    rescue StandardError => e
      puts "An unexpected error occured on Imap: #{e.message}"
      shutdown
    end
  end

  def shutdown
    connection.logout if connection && !connection.disconnected?
    connection.disconnect if connection && !connection.disconnected?
  end
end
