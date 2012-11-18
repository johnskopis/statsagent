require 'collectors/base'
class HeartbeatCollector < BaseCollector
  def initialize(id, interval, *args)
    @collector_name = :heartbeat
    @collector_type = :heartbeat
    @heartbeat = 0
    @started = Time.now
    super
  end

  def heartbeat
    #@logger.debug "incrementing heartbeat started at #{@started}"
    @heartbeat += 1
  end

  def dump(output)
    #@logger.debug "incremented heartbeat"
  end
end
