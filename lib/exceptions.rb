require 'json'

class Exception
  def to_json
    {
      code: @status || -1,
      message: self.message
    }.to_json
  end
end

class CollectorBaseException < Exception
  attr_reader :message, :status
  def initialize(status = -1)
    @message = "A #{self.class} exception has occured"
    @status = status
  end
end

class UnknownCollector < CollectorBaseException; end
class UnknownCollectorType < CollectorBaseException; end
