#!/usr/bin/env ruby
require 'thor'
require 'redis'
require 'json'

class CreateCreative < Thor
  desc 'new CreativeId CreativeFilename', 'Creates a creative file'

  def new(creative_id=1, creative_file='creative.json')
    creative = {
        creative_id: creative_id
    }

    File.open(creative_file, 'w') { |f| f.write(JSON.generate(creative)) }
  end

  desc 'body BodyFilename CreativeFilename', 'Adds body text'

  def body(body_file, creative_file = 'creative.json')
    creative = JSON.parse(File.read(creative_file), symbolize_names: true)

    creative[:body] = File.read(body_file)

    File.open(creative_file, 'w') { |f| f.write(JSON.generate(creative)) }
  end

  desc 'deal_url url CreativeFilename', 'Adds deal url'

  def deal_url(url, creative_file = 'creative.json')
    creative = JSON.parse(File.read(creative_file), symbolize_names: true)

    creative[:deal_url] = url

    File.open(creative_file, 'w') { |f| f.write(JSON.pretty_generate(creative)) }
  end

  desc 'unsubscribe templateFile CreativeFilename','Adds an unsubscribe template'

  def unsubscribe(template_file,creative_file)
    creative = JSON.parse(File.read(creative_file), symbolize_names: true)

    creative[:unsubscribe_template] = File.read(template_file)

    File.open(creative_file, 'w') { |f| f.write(JSON.pretty_generate(creative)) }
  end
end

CreateCreative.start