require_relative '../../../../config/imap'

module Emails
  module Parsers
    module Gmail
      class OrderParser
        SENDER_DOMAIN_FILTER = '@gmail.com'
        SUBJECT_PARSER = /order-\d+/i
        MAIL_BOX = 'INBOX'
        DESIRED_ATTRIBUTES = ['UID', 'BODY.PEEK[HEADER.FIELDS (SUBJECT FROM)]', 'BODY.PEEK[TEXT]']

        def initialize
          @imap = Imap.new
          @today_date_imap_format = '28-Sep-2025' #Date.today.strftime('%d-%b-%Y')
          @search_criteria = search_criteria
          @emails_to_process = []
        end

        def self.call
          new.call
        end

        def call
          run
        end

        private

        def run
          begin
            @imap.login
            @imap.connection.select(MAIL_BOX)
            fetch_uids
            fetch_emails
            process_emails
          rescue StandardError => e
            puts "An unexpected error occured on Order Parser: #{e}"
          ensure
            @imap.shutdown
          end
        end

        def search_criteria
          [
            'ON', @today_date_imap_format,
            'SUBJECT', 'order-',
            'FROM', SENDER_DOMAIN_FILTER
          ]
        end

        def fetch_uids
          @uids = @imap.connection.uid_search(@search_criteria)

          return @uids if !@uids.empty?

          raise 'No emails matched the initial date or subject criteria'
        end

        def fetch_emails
          @uids.each_slice(100) do |batch_uids|
            fetch_data = @imap.connection.uid_fetch(batch_uids, DESIRED_ATTRIBUTES)
            fetch_data.each do |message|
              header = message.attr['BODY[HEADER.FIELDS (SUBJECT FROM)]']
              body_text = message.attr['BODY[TEXT]']

              subject = header[/Subject: (.*)\r\n/i, 1]&.strip
              from = header[/From: (.*)\r\n/i, 1]&.strip

              if subject && subject.match?(SUBJECT_PARSER)
                @emails_to_process << {
                  uid: message.uid,
                  subject: subject,
                  from: from,
                  body: body_text
                }
              end
            end
          end
        end

        def process_emails
          if @emails_to_process.empty?
            puts "No emails matched the full regex pattern(#{SUBJECT_PARSER.source})"
          else
            puts "\n--- Found Order Emails (#{@emails_to_process.count}) ---"
            @emails_to_process.each do |email|
              refined_body = email[:body].split("\n").select{|line| line.include?('Teste') && !line.include?('<')}.first.strip
              puts "\n============================================"
              puts "UID: #{email[:uid]}"
              puts "FROM: #{email[:from]}"
              puts "Subject: #{email[:subject]}"
              puts "Body: #{refined_body}"
              puts "[... Full body Fetched ...]"
              puts "\n============================================"

              Order.find_by(id: email[:subject]).update(name: refined_body)
            end
          end
        end
      end
    end
  end
end
