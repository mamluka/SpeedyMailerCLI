#!/usr/bin/env ruby
require 'thor'
require 'redis'
require 'json'
require 'rest-client'
require 'logger'
require 'tire'

class Migrations< Thor
  desc 'getIds indexName chunkSize inputFile', 'Get ids using a query specified in the input file'
  option :total, type: :boolean, default: false

  def get_ids(index, chunk_size, input_file='ids.json')

    Signal.trap('PIPE', 'EXIT')
    logger = Logger.new('get-ids.log')

    json_parse = JSON.parse(File.read(input_file), symbolize_names: true)
    json_parse = json_parse.merge({fields: %w(ids)})
    begin
      total_response = RestClient.post "http://localhost:9200/#{index}/_search", json_parse.to_json, :content_type => :json, :accept => :json
      total_response = JSON.parse(total_response, symbolize_names: true)
    rescue => exception
      p exception.response
    end

    count = total_response[:hits][:total]

    $stdout.puts count if options[:total]

    json_parse = json_parse.merge({size: chunk_size})
    total_ids = 0

    while total_ids < count

      json_parse = json_parse.merge({from: total_ids})
      begin
        response = RestClient.post "http://localhost:9200/#{index}/_search", json_parse.to_json, :content_type => :json, :accept => :json
        response = JSON.parse(response, symbolize_names: true)
        total_ids = total_ids + response[:hits][:hits].length

        logger.info "#{total_ids} ids #{(total_ids*100/count).to_f.round(2)}% done"

        response[:hits][:hits].each { |x| $stdout.puts x[:_id] }

      rescue => exception
        p exception
      end

    end
  end

  desc 'update indexName chunkSize inputFile', 'Updates elastic with the script'

  def update(index, chunk_size, ids_file, input_file='update.json')
    ids = Array.new
    start_end = Time.new

    chunk_size = chunk_size.to_i

    logger = Logger.new('update-script-log.log')
    counter = 0

    File.open(ids_file).each do |id|
      ids << id.strip

      counter = counter + 1


      if ids.length % chunk_size == 0

        docs = ids

        update_docs = docs.map { |x|
          {
              id: x,
              script: File.read(input_file)
          }
        }


        s = Tire.index index do
          bulk :update, update_docs
        end

        bulk_time = Time.new - start_end
        logger.info "Took #{bulk_time}, we processed #{counter} [#{chunk_size/bulk_time}] docs/sec"
        start_end = Time.new

        logger.info s.to_json

        ids.clear
      end

    end
  end
end

Migrations.start