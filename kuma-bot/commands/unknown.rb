module SlackRubyBot
  module Commands
    class Unknown < Base
      def self.call(client, data, _match)
        send_message client, data.channel, "Anyone looking for me?"
      end
    end
  end
end
