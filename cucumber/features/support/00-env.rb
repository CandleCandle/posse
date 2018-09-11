
CUCUMBER_DIR = File.expand_path('../..', File.dirname(__FILE__))

AfterConfiguration do
  IRCD = Ircd.new('localhost', 6667)
end

Before do |scenario|
  IRCD.start
end

After do |scenario|
  IRCD.stop

  IRCD.logs.each do |k, v|
    puts "\n\n\tServer log for: #{k}"
    v.each {|l| puts l}
  end

  @clients ||= []
  @clients.each_index do |i|
    client = @clients[i]
    puts "\n\nClient log for #{i}"
    a = client.responses.to_a
    a.each_index {|i| puts a[i]}
  end
end

at_exit do
end

# vi: sw=2 ts=2 sts=2 et