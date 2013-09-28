require_relative 'smtp-recipient-verify'
require_relative 'yahoo-recipient-verify'

require_relative '../drones/drone-config'
require_relative '../core/jobs'

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
      get_session = @yahoo.create_yahoo_app_session

      if not get_session
        IndexLogMessage.perform_async 'Was not able to login to yahoo page, please check login CAPCHA using proxy', $config[:domain]
        return false
      end

      is_good = @yahoo.verify recipient
    else
      is_good = @smtp.verify recipient
    end
    is_good
  end
end