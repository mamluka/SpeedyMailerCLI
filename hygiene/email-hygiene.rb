require_relative 'smtp-recipient-verify'
require_relative 'yahoo-recipient-verify'

require_relative '../drones/drone-config'

class EmailVerify
  def initialize
    @supported_providers = %W{yahoo gmail aol hotmail live msn}
    @smtp = SMTPRecipientVerify.new $config[:domain]
    @yahoo = YahooEmailVerifier.new
  end

  def verify(recipient)
    provider_match = recipient.scan(/@(.+?)\./)[0]

    return false if provider_match.nil?

    provider = provider_match[0]

    return false if not @supported_providers.include? provider

    if provider == 'yahoo'
      @yahoo.create_yahoo_app_session
      is_good = @yahoo.verify recipient
    else
      is_good = @smtp.verify recipient
    end
    is_good
  end
end