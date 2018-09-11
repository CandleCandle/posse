require 'process-helper'

class Ircd
  attr_reader :host, :port


  def initialize(host, port)
    @host=host
    @port=port
  end

  def start()
    @process = ProcessHelper::ProcessHelper.new({print_lines: true})
    @process.start([CUCUMBER_DIR + '/../target/build/posse', '--host', @host, '--port', @port.to_s, '--name', 'server_name'], /listening on: .*:#{@port}/)
  end

  def stop()
    @process.kill
    @process.wait_for_exit
  end
    
end


# vi: sw=2 ts=2 sts=2 et
