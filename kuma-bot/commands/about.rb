module KumaBot
  module Commands
    class Default < SlackRubyBot::Commands::Base
      match(/^(?<bot>kumakun)$/)

      def self.call(client, data, __match)
        send_message_with_gif client, data.channel, KumaBot::ABOUT, 'google'
      end
    end
  end
end
