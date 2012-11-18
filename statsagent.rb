require 'sinatra'
require 'json'
require 'logging'
$LOAD_PATH << File.join(File.dirname(__FILE__), 'lib')
require 'exceptions'
require 'statsmanager'
#require 'active_support/core_ext/hash/keys'


class StatsAgent < Sinatra::Base
  use Rack::Logger

  configure do
    enable :logging, :dump_errors, :raise_errors, :show_exceptions
    disable :reload_templates, :protection, :caching
  end

  def initialize
    @app = app
    Logging::Config::YamlConfigurator.load('config.yml')
    @logger = Logging.logger[self]
    @manager = StatsManager.instance
    @logger.info "app setup complete"
  end

  get '/' do
    @manager.collectors.values.map(&:to_hash).to_json
  end

  get '/heartbeat' do
    @manager.heartbeat.to_json
  end

  get '/add/:collector/:type/:interval' do
    begin
      raise UnknownCollector unless params[:type]
      @manager.add_collector(params[:collector].to_sym, params.delete('interval').to_f, params.symbolize_keys).to_json
    rescue CollectorBaseException => e
      e.to_json
    end
  end

  get '/remove/:id' do
    @manager.remove_collector(params[:id].to_i).to_json
  end
end
