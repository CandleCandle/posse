


class IrcClient
  attr_reader :host, :port, :responses, :sock

  def initialize(host, port)
    @host=host
    @port=port
  end

  def start
    @sock = TCPSocket.new IRCD.host, IRCD.port
    @responses = ProcessHelper::ProcessLog.new(@sock, {print_lines: false}).start
    self
  end

  def send(line)
    @sock.write line
    @sock.flush
  end
    
end


# vi: sw=2 ts=2 sts=2 et
