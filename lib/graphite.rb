require 'socket'

class Graphite
  def initialize(host)
    @host = host
    @logger = Logging.logger[self]
    @logger.debug "graphite host #{@host}"
  end

  def socket
    return @socket if @socket && !@socket.closed?
    @socket = TCPSocket.new(@host, 2003)
  end

  def report(key, value, time = Time.now)
    begin
      socket.write("#{key} #{value.to_f} #{time.to_i}\n")
    rescue Errno::EPIPE, Errno::EHOSTUNREACH, Errno::ECONNREFUSED
      @socket = nil
      nil
    end
  end

  def close_socket
    @socket.close if @socket
    @socket = nil
  end
end
