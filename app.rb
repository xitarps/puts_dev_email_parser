require 'date'

require_relative 'models/emails/parsers/gmail/order_parser'

class App
  def call
    Emails::Parsers::Gmail::OrderParser.call
  end
end

App.new.call
