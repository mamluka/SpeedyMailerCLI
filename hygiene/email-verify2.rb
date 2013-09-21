require 'net/telnet'
require 'clockwork'

include Clockwork

Clockwork.configure do |config|
  config[:sleep_timeout] = 5
  config[:logger] = Logger.new('verify-email-job.log')
  config[:tz] = 'EST'
  config[:max_threads] = 15
end



logger = Logger.new('email-hygiene.log')

emails = File.readlines(ARGV[0]).map { |x| x.strip }

verify = SMTPRecipientVerify.new ARGV[1]

handler do |job|
  email = emails.shift
  logger.info "about to check #{email}"

  is_good = verify.verify email
  logger.info "#{email} is #{is_good ? 'Good' : 'Bad'}"

  $stdout.puts email if is_good
end


every 8.seconds, 'email.verify'

verifier = YahooEmailVerifier.new
verifier.create_yahoo_app_session

File.open(ARGV[0]).each do |line|
  is_good = verifier.verify line.strip

  $stdout.puts "#{line} #{is_good ? 'Good' : 'Bad'}"
end
