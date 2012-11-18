require 'singleton'
require 'active_support/core_ext/hash/keys'

class StatsManager
  include Singleton
  attr_reader :collectors, :heartbeat

  def initialize
    @logger = Logging.logger[self]
    @logger.debug "creating #{self.class} instance"
    @id = 0
    @collectors = {}
    @heartbeat = @collectors[add_collector(:heartbeat,1)]
    init_graphite_config
    init_collectors
  end

  def init_collectors(config = './config.yml')
    YAML.load_file(config)['collectors'].each_pair do |collector, ci|
      ci.each do |config|
        add_collector(collector.to_sym, config.delete('interval').to_f, config.symbolize_keys.merge(graphite_host: @graphite_host) )
      end
    end
  end

  def init_graphite_config(config = './config.yml')
    YAML.load_file(config)['graphite'].each_pair do |name, config|
      @graphite_host = config
      @logger.debug "Connecting to graphite host #{@graphite_host}"
    end
  end

  def add_collector(collector, *args)
    kls = "#{collector.capitalize}Collector"
    begin
      require "collectors/#{collector}"
      klass = Kernel.const_get(kls)
    rescue NameError, LoadError
      raise UnknownCollector
    end
    @id += 1
    begin
      @collectors[@id] = klass.new(@id, *args)
    rescue => e
      @logger.error "error initializing #{kls}"
      @logger.error e
    end
    @id
  end

  def remove_collector(collector_id)
    @collectors[collector_id].cancel if @collectors[collector_id].respond_to?('cancel')
    @collectors.delete collector_id
    'OK'
  end
end
