#!/usr/bin/env ruby
require 'thor'
require 'redis'
require 'json'

require_relative '../core/creative_id'

class AddCreative < Thor
  desc 'add creativeId BodyFile', 'Adds a creative to redis with the given id and body taken from the file'

  def add(creative_id=1, body_file='creative.json')
    redis = Redis.new

    body = File.read(body_file)

    redis.set CreativeId.generate_id(creative_id), body
    p "#{creative_id} was added with the body #{body[0..100]}"
  end

  desc 'list', 'List creatives'

  def list
    redis = Redis.new

    keys = redis.keys(CreativeId.prefix + ':*')
    if keys.empty?
      $stdout.puts 'Mo creatives found'
      exit 0
    end
    keys.each { |x|
      creative_json = redis.get x
      creative = JSON.parse(creative_json, symbolize_names: true)

      $stdout.puts "#{x} subject: #{creative[:subject]}"
    }
  end
end

AddCreative.start