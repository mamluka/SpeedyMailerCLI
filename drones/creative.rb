require 'redis'
require 'json'

require_relative '../core/creative_id'

class Creative
  def self.get(creative_id)
    redis = Redis.new
    creative_json = redis.get CreativeId.generate_id(creative_id)
    JSON.parse(creative_json, symbolize_names: true)
  end
end

