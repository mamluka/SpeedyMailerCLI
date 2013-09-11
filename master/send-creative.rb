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
  def scheduled_sending(creative_id, domain_groups)

    handler do |job|

      Drone.each { |drone|
        domain_groups.each { |k, v|
          Sidekiq::Client.push('queue' => drone.drone_id, 'class' => SendCreativeByDrone, 'args' => [creative_id, v.shift])
        }
      }

    end

    every 20.seconds, 'send.domain'

    Clockwork::run
  end
end

class SendCreative < Thor
  desc 'send creativeId emailsFile', 'Start a queue to all drones sending out creative to the email list'

  def send(creative_id=1, email_list='emails.csv')
    loader = DomainGroupsLoader.new
    domain_groups = loader.load email_list

    sending = Sending.new
    sending.scheduled_sending creative_id, domain_groups
  end

  desc 'drones', 'List active drones'
  option :all, type: :boolean

  def drones
    Drone
    .each { |drone|
      next unless options[:all] ? true : (Time.now - drone.live_at) < 300
      p "#{drone.drone_id} was last live at #{drone.live_at}"
    }
  end
end

SendCreative.start