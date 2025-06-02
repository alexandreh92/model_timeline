class RequestMock
  attr_accessor :remote_ip

  def initialize(ip = '192.168.1.1')
    @remote_ip = ip
  end
end
