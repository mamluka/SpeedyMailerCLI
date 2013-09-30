#!/usr/bin/env ruby
require 'thor'
require 'clockwork'
require 'tire'

require_relative '../core/jobs'
require_relative 'master-core/domain-group-loader'
require_relative '../core/orm'

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

    allowed_domain_group = domain_groups.select { |k| allowed_to_clean.include? k }

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

    every interval.to_i.seconds, 'clean.recipient'

    Clockwork::run
  end

  desc 'dump_clean', 'dumps to stdout all good emails'

  def dump_clean
    Tire.search 'hygiene' do
      result = query do
        term :valid, true
      end

      size 100000

      result.results.map { |x| x.to_hash[:recipient] }.uniq.each { |x| $stdout.puts x }
    end
  end

  desc 'count_domains listFile', 'Count the domain groups'

  def count_domains(list_file)
    loader = DomainGroupsLoader.new
    domain_groups = loader.load list_file

    domain_groups.each { |k, v| $stdout.puts "#{k} #{v.length}" }
  end

  desc 'filter', 'filter a list using clean list'

  def filter(clean_file, list_file)
    emails = File.readlines(clean_file).map { |x| x.strip }

    File.open(list_file, 'r').each do |line|
      $stdout.write line if emails.any? { |x| line.include? x }
    end
  end
end

Hygiene.start