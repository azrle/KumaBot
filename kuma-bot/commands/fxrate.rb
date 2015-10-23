require 'date'

module KumaBot
  module Commands
    class Fxrate < SlackRubyBot::Commands::Base
      match(/^kumakun fxrate\s+(?<expression>.+)$/) do |client, data, match|
        expression = match['expression'].strip
        if expression =~ /--date\s+(\d{4}-\d{2}-\d{2})/
          date = $1
        else
          date = Date.today.to_s
        end
        if expression =~ /^([A-Za-z]+)\s+([A-Za-z]+)/
          from = $1.upcase
          to = $2.upcase
          rate = `curl http://currencies.apps.grandtrunk.net/getrate/#{date}/#{from}/#{to}`
          if rate != "False"
            send_message client, data.channel, "1 #{from} = #{rate} #{to}"
          else
            send_message client, data.channel, "Something wrong kuma >__<"
          end
         else
          send_message client, data.channel, "Something wrong kuma >__<"
        end
      end
    end
  end
end
