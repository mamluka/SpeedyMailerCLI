#!/usr/bin/env ruby
require 'thor'
require 'tire'

Tire.configure do
  url ENV['MASTER_STATS_ES_URL'] || 'localhost:9200'
end

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
  option :recent, type: :numeric, default: 20
  option :action, type: :string
  option :total, type: :boolean


  def clicks(creative_id)

    get_recipients = options[:recent]
    action = options[:action]
    total = options[:total]

    result = Tire.search('marketing') do
      query do
        boolean do
          must { term :creative_id, creative_id }
          must { term :action, action } if not action.nil?
        end
      end

      size get_recipients

      sort { by :time, 'desc' }

      facet 'domains' do
        terms :drone_domain
      end

      facet 'actions' do
        terms :action
      end
    end

    output = Array.new

    result.results.map { |x| x.to_hash }.each { |x|
      output << "#{x[:recipient]} did a #{x[:action]} originated at #{x[:drone_domain]}"
    }

    if total
      result.results.facets['domains']['terms'].each do |facet|
        output << "#{facet['term']}: #{facet['count']}"
      end
    end

    if total
      result.results.facets['actions']['terms'].each do |facet|
        output << "#{facet['term']}: #{facet['count']}"
      end
    end

    output.each { |x| $stdout.puts x }

  end

  desc 'Report creativeId', 'Shows a action to send ratio reports'
  option :ratio, type: :string
  option :size, type: :numeric, default: 1000
  option :include_zero, type: :boolean
  option :limits, type: :string, default: '0/10 0-1'
  option :include_actual, type: :boolean, default: true
  option :drone, type: :string

  def report(creative_id)
    ratio = options[:ratio]
    facet_size = options[:size]
    drone = options[:drone]

    stats = Tire.search 'stats' do
      query do
        boolean do
          must { term :creative_id, creative_id }
          must { term :drone_domain, drone } if not drone.nil?
        end
      end

      facet 'sent' do
        terms :domain_group, size: facet_size
        facet_filter :term, {status: 'sent'}
      end

      facet 'bounced' do
        terms :domain_group, size: facet_size
        facet_filter :term, {status: 'bounced'}
      end

      facet 'deferred' do
        terms :domain_group, size: facet_size
        facet_filter :term, {status: 'deferred'}
      end

    end

    marketing = Tire.search 'marketing' do
      query do
        boolean do
          must { term :creative_id, creative_id }
          must { term :drone_domain, drone } if not drone.nil?
        end
      end
      facet 'click' do
        terms :domain_group, size: facet_size
        facet_filter :term, {action: 'click'}
      end

      facet 'unsubscribe' do
        terms :domain_group, size: facet_size
        facet_filter :term, {action: 'unsubscribe'}
      end

      facet 'open' do
        terms :domain_group, size: facet_size
        facet_filter :term, {action: 'open'}
      end
    end

    if not ratio.nil?
      ratio_params = ratio.split('/')

      limits = options[:limits].scan(/(\d+?)\/(\d+?)\s(\d+\.?\d*?)-(\d+\.?\d*?)$/)[0]

      if limits.nil?
        $stderr.puts 'Limits is not in the correct format'
      end

      limits = limits.map { |x| x.to_f }

      output = Array.new

      marketing_action_facets = marketing.results.facets.map do |key, facet|
        {name: key,
         terms: facet['terms'].map { |term|
           {term: term['term'],
            count: term['count'].to_f,
            name: key} }
        }
      end


      stats_transport_facets = stats.results.facets.map do |key, facet|
        {name: key,
         terms: facet['terms'].map { |term|
           {term: term['term'],
            count: term['count'].to_f,
            name: key} }
        }
      end

      combined_facets = marketing_action_facets.concat(stats_transport_facets)

      combined_facets.select { |x| x[:name] == ratio_params[1] }.first[:terms].each do |facet|
        total_transport = facet[:count].to_f

        next if total_transport <= limits[1]
        marketing_action = combined_facets.select { |x| x[:name] == ratio_params[0] }.first[:terms].select { |x| x[:term] == facet[:term] && x[:name] != facet[:name] }.first

        total_action = marketing_action.nil? ? 0 : marketing_action[:count]

        next if total_action <= limits[0]

        single_stat = (total_action/total_transport).round(4)

        next if single_stat == 0.0 && !options[:include_zero]
        next if single_stat <= limits[2] || single_stat >= limits[3]

        line = "#{facet[:term]} #{single_stat}"
        line = "#{line} [#{total_action}/#{total_transport}]" if options[:include_actual]

        output << line

      end

      output.each { |x| $stdout.puts x }
    end

  end

  desc 'remove_tests', 'Remove tests data'
  def remove_tests

  end
end

Stats.start