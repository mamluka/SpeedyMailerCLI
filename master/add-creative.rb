#!/usr/bin/env ruby
require 'thor'
require 'redis'

class AddCreative < Thor
  desc 'add creativeId BodyFile', 'Adds a creative to redis with the given id and body taken from the file'

  def add(creative_id=1, body_file='creative.json')
    redis = Redis.new

    body = File.read(body_file)

    redis.set creative_id, body
    p "#{creative_id} was added with the body #{body[0..100]}"
  end
end

AddCreative.start