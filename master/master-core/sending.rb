class Sending
  def scheduled_sending(creative_id, domain_groups, interval)

    handler do |job|

      Drone.each { |drone|
        next if (Time.now - drone.live_at) > 300

        domain_groups.each { |k, v|
          next if v.empty?
          recipient = v.shift
          drone_id = drone.drone_id
          send_to_specific_drone drone_id, creative_id, recipient
        }
      }

      if domain_groups.all? { |k, v| v.empty? }
        puts 'Done sending all emails... exiting'
        exit 0
      end
    end

    every interval.seconds, 'send.domain'

    Clockwork::run
  end

  def send_to_specific_drone(drone_id, creative_id, recipient)
    Sidekiq::Client.push('queue' => drone_id, 'class' => SendCreativeByDrone, 'args' => [creative_id, recipient])
  end
end