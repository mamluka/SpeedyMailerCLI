#!/usr/bin/env ruby
require 'thor'
require 'tire'

class Stats < Thor
  desc 'sends creativeId', 'List sends'
  option :by, type: :string
  option :last, type: :numeric
  option :status, type: :string
  option :verbose, type: :array, enum: %w(domain, ago), default: %w()

  def sends(creative_id)
    by_drone = options[:by]
    last_sends = options[:last]
    status = options[:status]
    result = Tire.search('stats') do
      query do
        boolean do
          must { term :creative_id, creative_id }
          must { term :drone_domain, by_drone } if not by_drone.nil?
          must { term :status, status } if not status.nil?
        end
      end

      if not last_sends.nil?
        size last_sends
      else
        size 0
      end


      facet 'drones' do
        terms :drone_domain
      end

      facet 'status' do
        terms :status
      end

      sort { by :time, 'desc' }
    end

    if not last_sends.nil?
      result.results.map { |x| x.to_hash }.each { |x|
        out = x[:recipient]
        out = "#{out} #{x[:drone_domain]}" if options[:verbose].include? 'domain'
        out = "#{out} #{((Time.now.to_i - x[:time].to_i)/3600.0).round(1)}" if options[:verbose].include? 'ago'
        $stdout.puts out
      }

      exit 0
    end

    $stdout.puts 'Number of emails send by each drone:'
    result.results.facets['drones']['terms'].each do |facet|
      $stdout.puts "#{facet['term']}: #{facet['count']}"
    end

    $stdout.puts 'Status of emails sent:'
    result.results.facets['status']['terms'].each do |facet|
      $stdout.puts "#{facet['term']}: #{facet['count']}"
    end
  end

  desc 'clicks creativeId', 'List clicks opens and unsubscribes'
  option :recent, type: :boolean
  option :action, type: :string
  option :totals, type: :array

  def clicks(creative_id)

    get_recipients = options[:recent]
    action = options[:action]

    result = Tire.search('marketing') do
      query do
        bool do
          must { term :creative_id, creative_id }
          must { term :action, action } if not action.nil?
        end
      end

      if get_recipients
        size 50
      else
        size 0
      end

      sort { by :time, 'desc' }

      facet 'drones' do
        terms :drone_domain
      end

      facet 'actions' do
        terms :action
      end
    end

    output = Array.new

    if not options[:recent].nil?
      result.results.map { |x| x.to_hash }.each { |x|
        output << "#{x[:recipient]} did a #{x[:action]} originated at #{x[:drone_domain]}"
      }
    end

    totals = options[:totals]

    if not totals.nil?

      if totals.include? 'domains'
        result.results.facets['drones']['terms'].each do |facet|
          output << "#{facet['term']}: #{facet['count']}"
        end
      end

      if totals.include? 'actions'
        result.results.facets['actions']['terms'].each do |facet|
          output << "#{facet['term']}: #{facet['count']}"
        end
      end

    end

    output.each { |x| $stdout.puts x }


  end

  desc 'Report creativeId', 'Shows a action to send ratio reports'

  def report(creative_id)

  end

  desc 'remove_tests', 'removes tests from the indexes'

  def remove_tests
    Tire.index 'stats' do
      delete
    end
  end
end

Stats.start