require 'mongoid'

Mongoid.load!(File.dirname(__FILE__) + '/mongoid.yml', :development)

class Drone
  include Mongoid::Document

  field :_id, type: String, default: -> { drone_id }
  field :live_at, type: DateTime
  field :drone_id, type: String
end