require 'json'

module KumaBot
  module Commands
    class Giphy < SlackRubyBot::Commands::Base
      match(/^kumakun gif\s+(?<expression>.+)$/) do |client, data, match|
        expression = match['expression'].strip

        send_message_with_gif client, data.channel, "I've got one for you:", expression
      end

      match(/^kumakun sticker\s+(?<expression>.+)$/) do |client, data, match|
        expression.gsub!(/\s+/, "+")
        response = `curl 'http://api.giphy.com/v1/stickers/random?api_key=dc6zaTOxFJmzC&tag=#{expression}'`
        result = JSON.parse(response)
        unless result["data"].empty?
          link = result["data"]["url"]
          send_message client, data.channel, "I've got one for you:\n#{link}"
        else
          send_message client, data.channel, "I didn't find such sticker T_T"
        end
      end
    end
  end
end
