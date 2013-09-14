#!/usr/bin/env ruby
require 'thor'
require 'redis'
require 'net/dns'
require 'tire'

class Lists < Thor
  desc 'clean emailFile', 'Clean an email file'

  def clean(email_file)
    bad_names = Array.new

    File.foreach(File.dirname(__FILE__) + '/bad.first.names.txt') { |line| bad_names << line.delete("\n") }

    File.foreach(email_file).each { |line|
      line = line.delete("\n")

      next unless line.match /^[A-Za-z0-9](([_\.\-]?[a-zA-Z0-9]+)*)@([A-Za-z0-9]+)(([\.\-]?[a-zA-Z0-9]+)*)\.([A-Za-z]{2,})$/
      next if bad_names.include? line.split('@').first
      begin
        next if Net::DNS::Resolver.start(line.split('@')[1], Net::DNS::MX).answer.length == 0
      rescue
        next
      end

      $stdout.print line + "\n"

    }
  end

  desc 'processed creativeId', 'List all emails that were sent,bounced or deferred for a given creativeId'

  def processed(creative_id)
    result = Tire.search('stats') do
      query do
        term :creative_id, creative_id
      end
      size 1000000
      fields [:recipient]
    end

    result.results.map { |x| x.to_hash }.uniq { |x| x[:recipient] }.each do |x|
      $stdout.puts x[:recipient]
    end
  end
end

Lists.start