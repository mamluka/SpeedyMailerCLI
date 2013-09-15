#!/usr/bin/env ruby
require 'thor'
require 'redis'
require 'sidekiq'
require 'json'
require 'clockwork'

require_relative '../core/orm'
require_relative '../core/jobs'

include Clockwork

class DomainGroupsLoader
  def load(file_name)
    domains = {
        gmail: %w(gmail.com googlemail.com),
        hotmail: %w(hotmail.com msn.com),
        yahoo: %w(yahoo.com)
    }

    domain_groups = Hash.new

    domains.each { |k, v|
      domain_groups[k] = Array.new
    }

    domain_groups[:other] = Array.new
    full_filename = File.dirname(__FILE__) + '/' + file_name

    File.open(full_filename, 'r').each do |line|
      line = line.strip

      matched = false
      domains.each { |k, v|
        if v.any? { |domain| line.match(domain) }
          domain_groups[k] << line
          matched = true
          break
        end
      }
      domain_groups[:other] << line unless matched
    end

    domain_groups
  end
end

class Sending
  def scheduled_sending(creative_id, domain_groups, interval)

    handler do |job|

      Drone.each { |drone|
        next if (Time.now - drone.live_at) > 300

        domain_groups.each { |k, v|
          next if v.empty?

          Sidekiq::Client.push('queue' => drone.drone_id, 'class' => SendCreativeByDrone, 'args' => [creative_id, v.shift])
        }
      }

      if domain_groups.all? { |k, v| v.empty? }
        puts 'Done sending all emails... exiting'
        exit 0
      end
    end

    every interval.minutes, 'send.domain'

    Clockwork::run
  end
end

class SendCreative < Thor
  desc 'send creativeId emailsFile interval(min)', 'Start a queue to all drones sending out creative to the email list'

  def send(creative_id=1, email_list='emails.csv', interval = 30)
    loader = DomainGroupsLoader.new
    domain_groups = loader.load email_list

    sending = Sending.new
    sending.scheduled_sending creative_id, domain_groups, interval.to_i
  end

  desc 'test_send creativeId Email', 'List active drones'

  def test_send(creative_id, email)

    domain_groups = Hash.new
    domain_groups[:other] = []

    if email.include?(',')
      domain_groups[:other] << email.split(',')
    else
      domain_groups[:other] << email
    end

    sending = Sending.new
    sending.scheduled_sending creative_id, domain_groups, 60
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
      out_array << dnsbl_client.lookup(ip) if options[:info].include? 'dnsbl'

      $stdout.puts out_array.join(' ')
    }
  end
end

SendCreative.start