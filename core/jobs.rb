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

class VerityRecipient
  include Sidekiq::Worker
  sidekiq_options :queue => :clean

  def perform(recipient)
    begin
      require_relative '../hygiene/email-hygiene'
      require_relative '../core/domain-groups'
      require_relative '../drones/drone-config'

      verify = EmailVerify.new
      is_good = verify.verify recipient

      IndexHygieneResult.perform_async({
                                           recipient: recipient,
                                           valid: is_good,
                                           domain: DomainGroups.extract_domain(recipient),
                                           time: Time.now.to_i,
                                           time_human: Time.now.to_s,
                                           drone_domain: $config[:domain],
                                       })
    rescue Exception => ex
      IndexLogMessage.perform_async(ex.message, $config[:domain])
    end
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

class IndexCreativeOpen
  include Sidekiq::Worker
  sidekiq_options :queue => :master

  def perform(open_data)
    require 'tire'

    Tire.index 'marketing' do
      store open_data
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

class IndexHygieneResult
  include Sidekiq::Worker
  sidekiq_options :queue => :master

  def perform(recipient)
    require 'tire'

    Tire.index 'hygiene' do
      store recipient
    end

  end

end

class IndexLogMessage
  include Sidekiq::Worker
  sidekiq_options :queue => :master

  def perform(log_message, drone_domain)
    require 'tire'

    Tire.index 'log' do
      log = {
          message: log_message,
          drone_domain: drone_domain,
          time: Time.now.to_i,
          time_human: Time.now.to_s,
      }

      store log
    end

  end

end