require_relative '../core/jobs'
require_relative 'drone-config'

include Clockwork

logger = Logger.new('drone.log')

drone_domain = $config[:domain]

handler do |job|
  ReportDroneToMaster.perform_async drone_domain
  logger.info "Updated drone at #{Time.now}"
end

every 60.seconds, 'report.drone'