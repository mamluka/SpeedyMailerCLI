require_relative '../core/jobs'
require_relative 'drone-config'

include Clockwork

logger = Logger.new('drone.log')

drone_id = $config[:droneId]

handler do |job|
  ReportDroneToMaster.perform_async drone_id
  logger.info "Updated drone at #{Time.now}"
end

every 2.seconds, 'report.drone'