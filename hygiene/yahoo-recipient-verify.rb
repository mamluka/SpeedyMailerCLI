require 'oauth'
require 'uri'
require 'json'
require 'mechanize'
require 'watir-webdriver'

class YahooEmailVerifier
  def initialize
    @consumer_key = 'dj0yJmk9NWU3bkd3N1ZpY2JVJmQ9WVdrOVMwZFpRMHRXTkdNbWNHbzlNams1TURneU5EWXkmcz1jb25zdW1lcnNlY3JldCZ4PTNh'
    @consumer_secret = '4aca5b5741578b97ef36b143d7f3d701a5210944'

    @yahoo_user_id = 'mamluka_xomix'
    @yahoo_password = '0953acb'

    @yahoo_oauth_request_token_path = '/oauth/v2/get_request_token'
    @yahoo_oauth_access_token_path = '/oauth/v2/get_token'
    @yahoo_oauth_authorize_path = '/oauth/v2/request_auth'

    @yahoo_user_login_url = "https://login.yahoo.com/"
    @yahoo_oauth_url = "https://api.login.yahoo.com"

    @yahoo_login_form_name = 'login_form'
    @yahoo_login_username_fieldname = 'login'
    @yahoo_login_password_fieldname = 'passwd'
    @yahoo_acceptance_form_name = 'rcForm'
    @verifier_code_span_name = 'shortCode'

  end

  def create_yahoo_app_session

    client = Watir::Browser.new :phantomjs

    @auth_consumer=OAuth::Consumer.new @consumer_key,
                                       @consumer_secret, {
            :site => @yahoo_oauth_url,
            :scheme => :query_string,
            :request_token_path => @yahoo_oauth_request_token_path,
            :access_token_path => @yahoo_oauth_access_token_path,
            :authorize_path => @yahoo_oauth_authorize_path
        }

    @request_token = @auth_consumer.get_request_token


    client.goto @yahoo_user_login_url

    client.text_field(name: 'login').set @yahoo_user_id
    client.text_field(name: 'passwd').set @yahoo_password

    client.button(name: '.save').click


    try_count = 0
    while !client.url.include?('my.yahoo.com') || try_count <= 20
      sleep 0.5
      try_count = try_count + 1
    end

    if try_count >= 20
      return false
    end

    client.goto @request_token.authorize_url

    client.button(name: 'agree').click
    code = client.span(id: 'shortCode')
    code.wait_until_present

    verifier_code = code.text

    @access_token=@request_token.get_access_token(:oauth_verifier => verifier_code)

  end

  def verify(recipient)
    begin
      response = call_yahoo recipient
      @json_hash = JSON.parse(response, :symbolize_names => true) # converts the Net object to a Hash

      !@json_hash[:query][:results].nil?
    rescue
      return false
    end

  end

  def call_yahoo(recipient)
    json_response = @access_token.request(:get, "http://query.yahooapis.com/v1/yql?q=select%20*%20from%20yahoo.identity%20where%20yid%3D\'#{recipient}\'&format=json&diagnostics=true&callback=")
    json_response.body
  end
end

