module KumaBot
  module Commands
    class Translate < SlackRubyBot::Commands::Base
      # microsoft user: 394598372@qq.com
      translator = BingTranslator.new('KumaBotBingTranslator', 'J0/t1Nhw+wLyXX7tOvzN1EAwbFbv4PYXNzzldj/RDSU=')

      match(/^kumakun t list$/) do |client, data, match|
        result = ""
        translator.supported_language_codes.each do |code|
          result += translator.language_names(code) + "  ==> #{code}\n"
        end
        send_message client, data.channel, "I can speak lots of languages!"
        send_message client, data.channel, "```#{result}```"
      end

      match(/^kumakun t\s+(?<to>.+?)\s+(?<expression>.+)$/) do |client, data, match|
        begin
          to = match['to']
          expression = match['expression'].strip

          if expression =~ /^(.+) --from (.+)$/
            phase = $1
            from = $2
            send_message client, data.channel, "#{from} => #{to}"
          else
            phase = expression
            from = translator.detect(phase)
            send_message client, data.channel, "#{from} *maybe:)* => #{to}"
          end
          send_message client, data.channel, "*" + translator.translate(phase, :from => from, :to => to) + "*"
        rescue StandardError => e
          send_message client, data.channel, "I got \"#{e.message}\". Check your expression again?"
        end
      end
    end
  end
end
