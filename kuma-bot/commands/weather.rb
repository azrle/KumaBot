require 'json'
require 'date'

module KumaBot
  module Commands
    class Weather < SlackRubyBot::Commands::Base
      match(/^kumakun w\s+(?<expression>.+)$/) do |client, data, match|
        expression = match['expression'].strip
        response = `curl 'https://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20weather.forecast%20where%20woeid%20in%20(select%20woeid%20from%20geo.places(1)%20where%20text%3D%22#{expression}%22)&format=json&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys'`
        parsed = JSON.parse(response)
        results = parsed["query"]["results"]["channel"]
        if results.nil?
          send_message client, data.channel, "Kuma doesn't think there exists such a place on the Earth >___<"
        else
          location = results["location"]
          temp = ((results["item"]["condition"]["temp"].to_f - 32.to_f) / 1.8.to_f).round(1).to_s
          text = results["item"]["condition"]["text"]

          send_message client, data.channel, "Current condition for *" + location["city"] + "*, *" + location["country"] + "*:"
          send_message client, data.channel, "\t#{temp}℃\t#{text}"

          forecast = results["item"]["forecast"]
          send_message client, data.channel, "Weather forecast:"
          forecast.each do |fore|
            d = Date.parse(fore["date"])
            day = fore["day"]
            high = ((fore["high"].to_f - 32.to_f) / 1.8.to_f).round(1).to_s
            low = ((fore["low"].to_f - 32.to_f) / 1.8.to_f).round(1).to_s
            text = fore["text"]
            send_message client, data.channel, "\t#{d} #{day}: #{low}~#{high}℃, #{text}"
          end
        end
      end
    end
  end
end
