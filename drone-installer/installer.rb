require 'sinatra/base'
require 'json'

class Installer < Sinatra::Base

  get '/install' do
    content_type 'text/plain'

    @drone_domain = params[:droneDomain]
    @master_domain = params[:masterDomain]

    erb :install
  end

  get '/create-drone' do
    content_type 'text/plain'
    config = JSON.parse(File.read(File.dirname(__FILE__) + '/config.json'), symbolize_names: true)

    @password = config[:password]

    erb :create_drone
  end
end