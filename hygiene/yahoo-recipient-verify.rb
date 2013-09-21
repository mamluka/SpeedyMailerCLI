require 'oauth'
require 'uri'
require 'json'
require 'mechanize'

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

    @auth_consumer=OAuth::Consumer.new @consumer_key,
                                       @consumer_secret, {
            :site => @yahoo_oauth_url,
            :scheme => :query_string,
            :request_token_path => @yahoo_oauth_request_token_path,
            :access_token_path => @yahoo_oauth_access_token_path,
            :authorize_path => @yahoo_oauth_authorize_path
        }

    @request_token = @auth_consumer.get_request_token

    myagent = Mechanize.new
    myagent.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    newpage1 = myagent.get @yahoo_user_login_url
    temp_jar = myagent.cookie_jar
    submit_form = newpage1.form_with(name: @yahoo_login_form_name) # find form name of form that submits the login
    submit_form.field_with(name: @yahoo_login_username_fieldname).value = @yahoo_user_id
    submit_form.field_with(name: @yahoo_login_password_fieldname).value = @yahoo_password
    File.open('newpage1.html','w') { |f| f.write newpage1.body }
    newpage2 = submit_form.click_button
    File.open('newpage2.html','w') { |f| f.write newpage2.body }
    myagent.cookie_jar = temp_jar

    agreement_page = myagent.get(@request_token.authorize_url)
    File.open('agreement.html','w') { |f| f.write agreement_page.body }
    agreement_form = agreement_page.form_with(name: @yahoo_acceptance_form_name)

    verifier_code_page = agreement_form.click_button # clicks first submit button

    verifier_code_html = verifier_code_page.search("//span[@id='shortCode']") # returns span html

    verifier_code = verifier_code_html.children.text # Nokogiri, the embedded parser within Mechanize, returns the full span text, but calling children will put the text of the span

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

