require 'sidekiq'

class ReportDroneToMaster
  include Sidekiq::Worker
  sidekiq_options :queue => :master

  def perform(drone_id)
    require_relative 'orm'

    drone = Drone.new(drone_id: drone_id, live_at: Time.now)

    drone.upsert
  end
end

class SendCreativeByDrone
  include Sidekiq::Worker

  def perform(creative_id, email)

    require_relative '../drones/drone'

    drone = Drone.new
    drone.send creative_id, email
  end
end

class IndexDroneSendingStats
  include Sidekiq::Worker
  sidekiq_options :queue => :master

  def perform(log_messages)

    require 'tire'

    Tire.index 'stats' do
      import log_messages
    end
  end

end

class IndexCreativeClick
  include Sidekiq::Worker
  sidekiq_options :queue => :master

  def perform(click_data)
    require 'tire'

    Tire.index 'marketing' do
      store click_data
    end

  end

end

class IndexRecipientUnsubscribe
  include Sidekiq::Worker
  sidekiq_options :queue => :master

  def perform(unsubscribe_data)
    require 'tire'

    Tire.index 'marketing' do
      store unsubscribe_data
    end

  end

end