#!/usr/bin/env ruby
require 'thor'
require 'tire'

class Stats < Thor
  desc 'sends creativeId', 'List sends'
  option :by, type: :string

  def sends(creative_id)
    by_drone = options[:by]

    result = Tire.search('stats') do
      query do
        boolean do
          must do
            term :creative_id, creative_id
            term :drone_domain, by_drone if not by_drone.nil?
          end
        end
      end
      size 0

      facet 'drones' do
        terms :drone_domain
      end

      facet 'status' do
        terms :status
      end

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
  option :r, type: :boolean

  def clicks(creative_id)
    get_recipients = options[:r]
    result = Tire.search('marketing') do
      query do
        term :creative_id, creative_id
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

    if options[:r]
      $stdout.puts 'List of the last 50 actions'
      result.results.map { |x| x.to_hash }.each { |x|
        $stdout.puts "#{x[:recipient]} did a #{x[:action]} originated at #{x[:drone_domain]}"
      }
    end

    $stdout.puts 'Actions taken on drones:'

    result.results.facets['drones']['terms'].each do |facet|
      $stdout.puts "#{facet['term']}: #{facet['count']}"
    end

    $stdout.puts 'Actions distribution:'
    $stdout.puts "Total actions #{result.results.facets['actions']['total']}"

    result.results.facets['actions']['terms'].each do |facet|
      $stdout.puts "#{facet['term']}: #{facet['count']}"
    end
  end


end

Stats.start