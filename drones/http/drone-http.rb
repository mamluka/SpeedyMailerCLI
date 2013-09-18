require 'sinatra/base'
require 'base64'
require 'geoip'
require 'json'

require_relative '../creative'
require_relative '../../core/jobs'
require_relative '../drone-config'
require_relative '../../core/domain-groups'

class DroneSite < Sinatra::Base

  helpers do
    def create_indexing_hash(action, payload, deal_url)

      db = GeoIP.new(File.dirname(__FILE__) + '/GeoLiteCity.dat')

      {
          action: action,
          creative_id: payload[0].to_i,
          recipient: payload[1],
          time: Time.now.to_i,
          time_human: Time.now.to_s,
          deal_url: deal_url,
          drone_domain: $config[:domain],
          domain_group: DomainGroups.extract_domain(payload[1]),
          referrer: request.referrer,
          user_agent: request.user_agent,
          ip: request.ip,
          location: db.city(request.ip).to_h
      }
    end
  end

  get '/deal/:payload' do

    payload = Base64.decode64(params[:payload]).split(',')
    creative = Creative.get payload[0]
    deal_url = creative[:deal_url]

    IndexCreativeClick.perform_async(create_indexing_hash('click', payload, deal_url))

    redirect to(deal_url), 303
  end

  get '/unsubscribe/:payload' do

    payload = Base64.decode64(params[:payload]).split(',')
    creative = Creative.get payload[0]
    deal_url = creative[:deal_url]

    IndexRecipientUnsubscribe.perform_async(create_indexing_hash('unsubscribe', payload, deal_url))

    unsubscribe_url = creative[:unsubscribe_url]

    if not unsubscribe_url.nil?
      redirect to(unsubscribe_url), 303
    else
      "The email address #{payload[1]} was successfully unsubscribe"
    end


  end

  get '/small-logo/:payload' do

    payload = Base64.decode64(params[:payload]).split(',')

    creative = Creative.get payload[0]
    deal_url = creative[:deal_url]

    IndexCreativeOpen.perform_async(create_indexing_hash('open', payload, deal_url))

    send_file(File.dirname(__FILE__) + '/static/logo.png')
  end

  get '/admin/postfix-log' do
    'Not working right now'
  end

  get '/*' do

    @domain = $config[:domain]
    erb :home
  end


end