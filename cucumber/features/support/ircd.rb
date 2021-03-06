require 'process-helper'

class Ircd
  attr_reader :host, :port


  def initialize(host, port)
    @host=host
    @port=port
  end

  def start()
    @process = ProcessHelper::ProcessHelper.new({print_lines: false})
    @process.start([CUCUMBER_DIR + '/../bin/posse', '--host', @host, '--port', @port.to_s, '--name', 'server_name'], /listening on: .*:#{@port}/)
  end

  def stop()
    @process.kill
    @process.wait_for_exit
  end

  def logs()
    {
      err: @process.get_log(:err),
      out: @process.get_log(:out)
    }
  end
    
end


# vi: sw=2 ts=2 sts=2 et
