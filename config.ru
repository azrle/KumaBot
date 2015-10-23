$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'kuma-bot'
require 'web'

Thread.new do
  begin
    KumaBot::App.instance.run
  rescue Exception => e
    STDERR.puts "ERROR: #{e}"
    STDERR.puts e.backtrace
    raise e
  end
end

run KumaBot::Web


