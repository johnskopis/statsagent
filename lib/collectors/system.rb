require 'collectors/base'

class SystemCollector < BaseCollector
  def initialize(id, interval, kwargs, *args)
    @collector_name = :system
    @collector_type = kwargs.delete(:type).to_sym
    @known_collectors = [:memory, :loadavg, :delay]
    super
  end

  def memory
    output = []
    File.open('/proc/meminfo').each do |line|
      line.match(/([^:]+):\s+([^\s]+)\s+(.*)/) do |matches|
        k=matches[1]
        v=matches[2]
        units=matches[3]
        output << [k,v]
      end
    end
    Hash[output]
  end

  def loadavg
    output = []
    loads = File.read('/proc/loadavg').split
    output << ['1min', loads[0]]
    output << ['5min', loads[1]]
    output << ['15min', loads[2]]
    output << ['runnable', loads[3].split('/').first]
    Hash[output]
  end

  def delay
    sleep 2
    {foo: 'bar'}
  end
end
