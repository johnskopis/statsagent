require 'eventmachine'
require 'thin'
require './statsagent'
EM.run do
#  run StatsAgent.new
  Thin::Server.start StatsAgent.new, '0.0.0.0', 9293
end
