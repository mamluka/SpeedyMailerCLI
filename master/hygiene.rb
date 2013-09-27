#!/usr/bin/env ruby
require 'thor'

require_relative '../core/jobs'
require_relative 'master-core/domain-group-loader'

include Clockwork

class Hygiene < Thor
  desc 'test_clean email droneId', 'Test cleaning of one email'

  def test_clean(recipient, drone_id)
    Sidekiq::Client.push('queue' => drone_id, 'class' => VerityRecipient, 'args' => [recipient])
  end

  desc 'clean listFile', 'Clean a whole list'

  def clean(list_file, interval)

    allowed_to_clean = [:aol, :yahoo, :gmail, :hotmail]

    loader = DomainGroupsLoader.new
    domain_groups = loader.load list_file

    allowed_domain_group = domain_group.select { |k| allowed_to_clean.include? k }

    handler do |job|

      Drone.each { |drone|
        next if (Time.now - drone.live_at) > 300

        allowed_domain_group.each { |k, v|
          next if v.empty?
          recipient = v.shift
          drone_id = drone.drone_id

          Sidekiq::Client.push('queue' => drone_id, 'class' => VerityRecipient, 'args' => [recipient])
        }
      }

      if domain_groups.all? { |k, v| v.empty? }
        puts 'Done cleaning all emails... exiting'
        exit 0
      end
    end

    every interval.minutes, 'clean.recipient'

    Clockwork::run
  end

end

Hygiene.start