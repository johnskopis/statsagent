require 'mysql2/em'

class MysqlCollector < BaseCollector
  def initialize(id, interval, kwargs, *args)
    @collector_name = :mysql
    @collector_type = kwargs.delete(:type).to_sym
    @known_collectors = [:stats, :variables, :delay]
    @hostname = kwargs[:host].split('.').first if kwargs[:host]
    cparms = kwargs.reject{|k| ![:username, :password, :host, :port, :socket, :database].include?(k) }
    Mysql2::Client.default_query_options.merge!(:symbolize_keys => true, :async => true, :as => :array)
    @client = Mysql2::EM::Client.new(cparms)
    super
  end

  def stats
    query
  end

  def variables
    query('show variables')
  end

  def delay
    query('select "a" as foo, sleep(10) as foobar')
  end

  def schedule
    @logger.info "scheduling #{self.class} every #{@interval}s"
    @timer = EM.add_periodic_timer(@interval) do
      deferred = wrap_dispatch
      deferred.callback do |result|
        wrap_collect simple_output(result)
      end if deferred
    end
  end

  private
  def query(sql = 'show global status')
    @client.query(sql)
  end

  def simple_output(result)
    output = result.each.map do |k,v|
      k = k.downcase
      ["#{k.split('_').first}.#{k}", v.to_i]
    end
    Hash[output]
  end
end
