require 'watir-webdriver'
require 'oauth'
require 'clockwork'
require 'securerandom'

require_relative '../../core/jobs'

include Clockwork

dump_file = File.dirname(__FILE__) +'/access-token-class-dump.dunp'

handler do |job|
  consumer_key = 'dj0yJmk9NWU3bkd3N1ZpY2JVJmQ9WVdrOVMwZFpRMHRXTkdNbWNHbzlNams1TURneU5EWXkmcz1jb25zdW1lcnNlY3JldCZ4PTNh'
  consumer_secret = '4aca5b5741578b97ef36b143d7f3d701a5210944'

  yahoo_user_id = 'mamluka_xomix'
  yahoo_password = '0953acb'

  yahoo_oauth_request_token_path = '/oauth/v2/get_request_token'
  yahoo_oauth_access_token_path = '/oauth/v2/get_token'
  yahoo_oauth_authorize_path = '/oauth/v2/request_auth'

  yahoo_user_login_url = "https://login.yahoo.com/"
  yahoo_oauth_url = "https://api.login.yahoo.com"

  client = Watir::Browser.new :phantomjs

  auth_consumer=OAuth::Consumer.new consumer_key,
                                    consumer_secret, {
          :site => yahoo_oauth_url,
          :scheme => :query_string,
          :request_token_path => yahoo_oauth_request_token_path,
          :access_token_path => yahoo_oauth_access_token_path,
          :authorize_path => yahoo_oauth_authorize_path
      }

  request_token = auth_consumer.get_request_token


  client.goto yahoo_user_login_url

  client.text_field(name: 'login').set yahoo_user_id
  client.text_field(name: 'passwd').set yahoo_password

  client.button(name: '.save').click

  try_count = 0
  while !client.url.include?('my.yahoo.com') && try_count <= 20
    sleep 0.5
    try_count = try_count + 1
  end

  if try_count >= 20
    $stdout.puts "Can't login to yahoo"
    FileUtils.rm dump_file

    screenshot_id = SecureRandom.uuid[0..6]

    client.screenshot.save screenshot_id

    IndexLogMessage.perform_async "Count not login to yahoo account, please fix it, screenshot saved #{screenshot_id}"
    return
  end

  client.goto request_token.authorize_url

  client.button(name: 'agree').click
  code = client.span(id: 'shortCode')
  code.wait_until_present

  verifier_code = code.text

  client.close

  File.open(dump_file, 'w') { |f| f.write Marshal.dump request_token.get_access_token(:oauth_verifier => verifier_code) }
end

every 45.minutes, 'refresh.yahoo.token'