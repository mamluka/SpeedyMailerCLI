require 'sinatra/base'

class Installer < Sinatra::Base

  get '/install' do
    content_type 'text/plain'

    @drone_domain = params[:droneDomain]
    @master_domain = params[:masterDomain]

    erb :install
  end
end