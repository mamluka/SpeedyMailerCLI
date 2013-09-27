#!/usr/bin/env ruby
require 'thor'
require 'redis'
require 'sidekiq'
require 'json'
require 'clockwork'

require_relative '../core/orm'
require_relative '../core/jobs'

require_relative 'master-core/domain-group-loader'
require_relative 'master-core/sending'

include Clockwork

class SendCreative < Thor
  desc 'send creativeId emailsFile interval(min)', 'Start a queue to all drones sending out creative to the email list'

  def send(creative_id=1, email_list='emails.csv', interval = 30)
    loader = DomainGroupsLoader.new
    domain_groups = loader.load email_list

    sending = Sending.new
    sending.scheduled_sending creative_id, domain_groups, interval.to_i
  end

  desc 'test_send drone_id creativeId Email', 'List active drones'

  def test_send(drone_id, creative_id, email)

    sending = Sending.new
    sending.send_to_specific_drone drone_id, creative_id, email
  end

  desc 'drones', 'List active drones'
  option :all, type: :boolean
  option :info, type: :array, enum: %w{domain ip dnsbl live}, default: 'domain'

  def drones

    require "dnsbl/client"

    dnsbl_client = DNSBL::Client.new

    Drone
    .each { |drone|
      next unless options[:all] ? true : (Time.now - drone.live_at) < 300
      out_array = Array.new
      out_array << drone.drone_id if options[:info].include? 'domain'

      ip = `/usr/bin/dig +noall +answer #{drone.drone_id} A | awk '{$5=substr($5,1,length($5)); print $5}' | tr  -d '\n'` if options[:info].include?('ip') || options[:info].include?('dnsbl')

      out_array << ip if options[:info].include? 'ip'
      out_array << drone.live_at if options[:info].include? 'live'

      if options[:info].include? 'dnsbl'
        lookup = dnsbl_client.lookup(ip)

        out_array << (lookup.empty? ? 'None' : lookup.map { |x| x.meaning }.join(','))
      end

      $stdout.puts out_array.join(' ')
    }
  end
end

SendCreative.start