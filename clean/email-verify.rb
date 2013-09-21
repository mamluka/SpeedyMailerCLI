require 'net/telnet'
require 'clockwork'

include Clockwork

Clockwork.configure do |config|
  config[:sleep_timeout] = 5
  config[:logger] = Logger.new('verify-email-job.log')
  config[:tz] = 'EST'
  config[:max_threads] = 15
end

class Verify

  def initialize(domain)

    @domain = domain
    @logger = Logger.new 'email-clean.log'

    @mx_servers = {
        aol: %w(mailin-01.mx.aol.com mailin-02.mx.aol.com mailin-03.mx.aol.com mailin-04.mx.aol.com),
        gmail: %w(gmail-smtp-in.l.google.com alt1.gmail-smtp-in.l.google.com alt2.gmail-smtp-in.l.google.com alt3.gmail-smtp-in.l.google.com alt4.gmail-smtp-in.l.google.com),
        hotmail: %w(mx1.hotmail.com mx2.hotmail.com mx3.hotmail.com mx4.hotmail.com),
        live: %w(mx1.hotmail.com mx2.hotmail.com mx3.hotmail.com mx4.hotmail.com),
        msn: %w(mx1.hotmail.com mx2.hotmail.com mx3.hotmail.com mx4.hotmail.com),
        earthlink: %w(mx1.earthlink.net mx2.earthlink.net mx3.earthlink.net mx4.earthlink.net),
        verizon: %w(relay.verizon.net),
        comcast: %w(mx1.comcast.net mx2.comcast.net),
        charter: %w(ib1.charter.net),
        juno: %w(mx.vgs.untd.com mx.dca.untd.com),
    }
  end


  def check(recipient)
    begin
      provider = recipient.scan(/@(.+?)\./)[0]

      if provider.nil?
        return false
      end

      mx_server_list = @mx_servers[provider[0].to_sym]

      if mx_server_list.nil?
        return false
      end

      status = Array.new
      mx_server = mx_server_list.sample

      @logger.info "using mx #{mx_server}"

      mail = Net::Telnet::new('Host' => mx_server, 'Timeout' => 10, 'Port' => 25)
      mail.telnetmode = false

      mail.cmd({'String' => "HELO #{@domain}", 'Match' => /250/}) { |mx_response| @logger.info mx_response }
      mail.cmd({'String' => "MAIL FROM: <david@#{@domain}>", 'Match' => /250/}) { |mx_response| @logger.info mx_response }
      mail.cmd({'String' => "RCPT TO: <#{recipient}>", 'Match' => /\d{3}/}) { |mx_response|
        @logger.info mx_response
        status = mx_response.scan(/\d{3}/).map { |x| x.to_i }
      }
      mail.close

      status.include? 250
    rescue Exception => e
      @logger.error recipient
      @logger.error e.message
      @logger.error e.backtrace
      false
    end

  end
end

logger = Logger.new('email-clean.log')

emails = File.readlines(ARGV[0]).map { |x| x.strip }

verify = Verify.new ARGV[1]

handler do |job|
  email = emails.shift
  logger.info "about to check #{email}"

  is_good = verify.check email
  logger.info "#{email} is #{is_good ? 'Good' : 'Bad'}"

  $stdout.puts email if is_good
end


every 8.seconds, 'email.verify'
