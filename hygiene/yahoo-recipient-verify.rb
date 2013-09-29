require 'oauth'
require 'uri'
require 'json'
require 'rest-client'

require_relative '../drones/drone-config'


class YahooEmailVerifier
  def verify(recipient)

    begin
      oauth_class_dump = RestClient.get "http://#{$config[:master]}:8085/token"
      access_token = Marshal.load oauth_class_dump

      response = call_yahoo recipient, access_token
      json_hash = JSON.parse(response, :symbolize_names => true) # converts the Net object to a Hash

      !json_hash[:query][:results].nil?
    rescue
      return false
    end

  end

  def call_yahoo(recipient, access_token)
    json_response = access_token.request(:get, "http://query.yahooapis.com/v1/yql?q=select%20*%20from%20yahoo.identity%20where%20yid%3D\'#{recipient}\'&format=json&diagnostics=true&callback=")
    json_response.body
  end
end

