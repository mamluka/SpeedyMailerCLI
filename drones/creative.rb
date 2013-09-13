require 'redis'
require 'json'

require_relative '../core/creative_id'

$creative_hash = Hash.new

class Creative
  def self.get(creative_id)
    redis = Redis.new
    $creative_hash[creative_id] = redis.get CreativeId.generate_id(creative_id) unless $creative_hash.has_key?(creative_id)

    JSON.parse($creative_hash[creative_id], symbolize_names: true)
  end
end

