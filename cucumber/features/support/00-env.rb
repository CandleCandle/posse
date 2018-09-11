
CUCUMBER_DIR = File.expand_path('../..', File.dirname(__FILE__))

AfterConfiguration do
  IRCD = Ircd.new('localhost', 6667)
end

Before do |scenario|
  IRCD.start
end

After do |scenario|
  IRCD.stop
end

at_exit do
  #
end

# vi: sw=2 ts=2 sts=2 et