#!/usr/bin/env ruby
require 'thor'
require 'tire'

class Stats < Thor
  desc 'sends creativeId', 'List sends'

  def sends(creative_id)
    result = Tire.search('stats') do
      query do
        term :creative_id, creative_id
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
        $stdout.puts "#{x[:recipient]} did a #{x[:action]}"
      }
    end

    $stdout.puts 'Actions taken on drones:'
    result.results.facets['drones']['terms'].each do |facet|
      $stdout.puts "#{facet['term']}: #{facet['count']}"
    end

    $stdout.puts 'Actions distribution:'
    result.results.facets['actions']['terms'].each do |facet|
      $stdout.puts "#{facet['term']}: #{facet['count']}"
    end
  end


end

Stats.start