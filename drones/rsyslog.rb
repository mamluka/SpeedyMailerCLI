require 'sidekiq'
require 'set'
require 'file-tail'

require_relative '../core/jobs'
require_relative 'drone-config'
require_relative '../core/domain-groups'

class LRUCreativeIdLocator
  def initialize(size)
    @set = Set.new
    @size = size
  end

  def put(queue_id, creative_id)
    if @set.length == @size
      @set.delete(@size)
    end

    @set << {queue_id: queue_id, creative_id: creative_id}
  end

  def get_creative_id(queue_id)
    creative_id = @set.select { |x| x[:queue_id] == queue_id }.first
    creative_id.nil? ? nil : creative_id[:creative_id]
  end
end

lru = LRUCreativeIdLocator.new 100
log_messages = Array.new
logger = Logger.new('/tmp/mail.log')

File.open('/var/log/mail.log') do |log|
  
  log.extend(File::Tail)
  log.interval = 10
  log.backward(0)
  log.tail { |line|  

  logger.info line

  sending_event = /:\s(.+?): to=<(.+?)>. relay=(.+?)\[.+?\].+?, delay=(.+?), delays=(.+?)\/(.+?)\/(.+?)\/(.+?),.+?status=(.+?)\s(.+$)/
  sending_event_match = line.scan(sending_event)

  logger.info "Match event #{sending_event_match}"

  creative_id_event = /:\s(\w+?):.+?Speedy-Creative-Id:\s(.+?)\s/
  creative_id_match = line.scan(creative_id_event)

  logger.info "Match creative Id #{creative_id_match}"

  if creative_id_match.length > 0
    lru.put creative_id_match[0][0], creative_id_match[0][1]
    logger.info "Matched #{creative_id_match[0][0]} to #{creative_id_match[0][1]}"
  end

  if sending_event_match.length > 0
    creative_id = lru.get_creative_id sending_event_match[0][0]

    if not creative_id.nil?
      log_messages << {
          _id: sending_event_match[0][0],
          creative_id: creative_id.to_i,
          recipient: sending_event_match[0][1],
          domain_group: DomainGroups.extract_domain(sending_event_match[0][1]),
          relay: sending_event_match[0][2],
          total_delay: sending_event_match[0][3],
          time_before_queue_manager: sending_event_match[0][4],
          time_in_queue_manager: sending_event_match[0][5],
          time_in_connection_setup: sending_event_match[0][6],
          time_in_trensmission: sending_event_match[0][7],
          status: sending_event_match[0][8],
          message: sending_event_match[0][9],
          drone_domain: $config[:domain],
          time: Time.now.to_i,
          time_human: Time.now.to_s
      }

      logger.info "Logged email to #{sending_event_match[0][1]} with status #{sending_event_match[0][8]} buffer size is #{log_messages.length}"
    end

  end

  if log_messages.length == 1
    logger.info 'Send indexing job'
    IndexDroneSendingStats.perform_async log_messages
    logger.info 'Finish Send indexing job'
    log_messages.clear

  end
  }

end
