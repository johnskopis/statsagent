require 'graphite'

class BaseCollector
  def initialize(id, interval, kwargs = {}, *args)
    @id = id
    @duration = @interval = interval
    @hostname ||= `hostname -s`.chomp
    @logger = Logging.logger[self]
    @timer = nil
    @graphite_host = kwargs[:graphite_host] || 'localhost'
    @graphite = Graphite.new @graphite_host
    @run = 0
    @stop = 0
    @ready = 0
    @errors = 0
    @attempts = 0

    @filter_keys ||= kwargs[:keys].split(/,/) if kwargs[:keys]

    if @collector_type && @known_collectors.include?(@collector_type.to_sym)
      schedule
    else
      @logger.error "not creating #{self} every #{@interval} seconds"
      raise UnknownCollectorType
    end
  end

  def wrap_collect(output)
    if @ready == 1
      begin
        dump output
      rescue => e
        @logger.error e
        @errors += 1
      ensure
        post_hook
      end
    end
  end

  def wrap_dispatch
    if @run == 0
      @run = 1
      @start = Time.now
      begin
        res = send @collector_type
        @ready = 1
      rescue => e
        @logger.error e
        @errors += 1
        @run = 0
      ensure
        check_errors
      end
    else
      @logger.info "interval (#{@interval}) shorter than duration(#{@duration}), rescheduling #{self} on completion"
      cancel unless @stop == 1
    end
    res
  end

  def post_hook
    check_duration
    check_errors
    @ready = 0
    @run = 0
    @stop = 0
  end

  def check_duration
    @duration = Time.now - @start
    if @duration > @interval
      @logger.warn "long collector (#{@collector_type}), rescheduling for #{@duration}s"
      cancel
      @interval = @duration
      schedule
    end
  end

  def check_errors
    if @errors >= 3
      @logger.warn "buggy collection, disabling"
      cancel
    end
  end

  def schedule
    c = Proc.new {
      wrap_dispatch
    }

    cb = Proc.new do |output|
      wrap_collect(output)
    end

    @timer = EM.add_periodic_timer(@interval) do
      EM.defer(c, cb)
    end
    @logger.debug "scheduled #{self} every #{@interval} seconds"
  end

  def dump(output)
    output.each do |k,v|
      if @filter_keys && @filter_keys.include?(k)
        @graphite.report(format(k), v, @start)
        @logger.debug "sending #{format k} = #{v}"
      elsif !@filter_keys
        @graphite.report(format(k), v, @start)
        @logger.debug "sending #{format k} = #{v}"
      end
    end if output
  end

  def cancel
    if @timer.respond_to?('cancel')
      @stop = 1
      @timer.cancel
      @logger.debug "cancelled #{self}"
    end
  end

  def format(k)
    "statsagent.#{@hostname}.#{@collector_name}.#{@collector_type}.#{k}"
  end

  def to_s
    "#{self.class}##{@collector_type}"
  end

  def to_hash
    {
      self.class => {
        id: @id,
        interval: @interval,
        type: @collector_type,
        duration: @duration,
        errors: @errors
      }
    }
  end
end
