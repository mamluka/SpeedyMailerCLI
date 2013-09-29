require 'sinatra/base'
require 'watir-webdriver'
require 'oauth'
require 'json'

class AccessTokenServer < Sinatra::Base

  get '/token' do
    File.read(File.dirname(__FILE__) + '/access-token-class-dump.dunp')
  end

end