require 'sinatra/base'
require 'omniauth'
require 'omniauth-yahoo'

OmniAuth.config.full_host = 'http://127.0.0.1:8081'

class Auth < Sinatra::Base
  use Rack::Session::Cookie, :secret => '123asd'

  use OmniAuth::Builder do
    provider :yahoo, 'dj0yJmk9WWdEN0pvSFYyRE1XJmQ9WVdrOU1HSjFlVGxWTm1VbWNHbzlNVGsyTURjMk1ESTJNZy0tJnM9Y29uc3VtZXJzZWNyZXQmeD00MQ--','a65ebe18eae6d2ff400f7edd0771de9670695383'
  end

  get '/auth/:provider/callback' do
    auth = request.env['omniauth.auth']
  end

end