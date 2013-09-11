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

    write_json(creative_file, creative)
  end

  desc 'body BodyFilename CreativeFilename', 'Adds body text'

  def body(body_file, creative_file = 'creative.json')
    creative = parse_creative_file(creative_file)

    creative[:body] = File.read(body_file)

    write_json(creative_file, creative)
  end

  desc 'deal_url url CreativeFilename', 'Adds deal url'

  def deal_url(url, creative_file = 'creative.json')
    creative = parse_creative_file(creative_file)

    creative[:deal_url] = url

    write_json(creative_file, creative)
  end

  desc 'unsubscribe templateFile CreativeFilename', 'Adds an unsubscribe template'

  def unsubscribe(template_file, creative_file)
    creative = parse_creative_file(creative_file)

    creative[:unsubscribe_template] = File.read(template_file)

    write_json(creative_file, creative)
  end

  desc 'unsubscribe_url url CreativeFilename', 'Adds unsubscribe url'

  def unsubscribe_url(unsubscribe_url, creative_file)
    creative = parse_creative_file(creative_file)

    creative[:unsubscribe_url] = unsubscribe_url

    write_json(creative_file, creative)
  end

  desc 'from fromName fromPrefix CreativeFilename', 'Adds unsubscribe url'

  def from(from_name, from_prefix, creative_file)
    creative = parse_creative_file(creative_file)

    creative[:from_name] = from_name
    creative[:from_prefix] = from_prefix

    write_json(creative_file, creative)
  end

  desc 'subject subject CreativeFilename', 'Adds unsubscribe url'

  def subject(subject, creative_file)
    creative = parse_creative_file(creative_file)

    creative[:subject] = subject

    write_json(creative_file, creative)
  end

  private

  def parse_creative_file(creative_file)
    JSON.parse(File.read(creative_file), symbolize_names: true)
  end

  def write_json(filename, body)
    File.open(filename, 'w') { |f| f.write(JSON.pretty_generate(body)) }
  end


end

CreateCreative.start