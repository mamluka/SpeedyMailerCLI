require 'sinatra/base'
require 'base64'

require_relative '../creative'
require_relative '../../core/jobs'
require_relative '../drone-config'

class DroneSite < Sinatra::Base

  get '/deal/:payload' do

    payload = Base64.decode64(params[:payload]).split(',')
    creative = Creative.get payload[0]

    deal_url = creative[:deal_url]

    IndexCreativeClick.perform_async({
                                         action: 'click',
                                         creative_id: payload[0].to_i,
                                         recipient: payload[1],
                                         time: Time.now.to_i,
                                         time_human: Time.now.to_s,
                                         deal_url: deal_url,
                                         drone_domain: $config[:domain],
                                     })

    redirect to(deal_url), 303
  end

  get '/unsubscribe/:payload' do

    payload = Base64.decode64(params[:payload]).split(',')
    creative = Creative.get payload[0]

    deal_url = creative[:deal_url]

    IndexRecipientUnsubscribe.perform_async({
                                                action: 'unsubscribe',
                                                creative_id: payload[0].to_i,
                                                recipient: payload[1],
                                                time: Time.now.to_i,
                                                time_human: Time.now.to_s,
                                                deal_url: deal_url,
                                                drone_domain: $config[:domain],
                                            })

    "The email address #{payload[1]} was successfully unsubscribe"
  end

end