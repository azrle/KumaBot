module KumaBot
  module Commands
    class Google < SlackRubyBot::Commands::Base
      match(/^kumakun g\s+(?<category>.+?)\s+(?<expression>.+)$/) do |client, data, match|
        category = match['category']
        expression = match['expression'].strip

        case category
        when "web" then
          handle_google_search(category, expression, client, data)
        when "blog" then
          handle_google_search(category, expression, client, data)
        when "book" then
          handle_google_search(category, expression, client, data)
        when "image" then
          handle_google_search(category, expression, client, data)
        when "news" then
          handle_google_search(category, expression, client, data)
        when "video" then
          handle_google_search(category, expression, client, data)
        else
          send_message client, data.channel, "I don't know >__<"
        end
      end

      def self.handle_google_search(category, expression, client, data)
        if expression =~ /(.+)\s+--(random|limit)/
          query = $1
        else
          query = expression
        end
        query = { query: expression }
        query[:cx] = ENV['GOOGLE_CSE_ID'] if ENV['GOOGLE_CSE_ID']
        c = category.slice(0,1).capitalize + category.slice(1..-1)
        results = eval("::Google::Search::#{c}.new(#{query})").to_a

        if expression =~ /--limit(\d+)/
          number = $1.to_i
        else
          number = 1
        end
        number.times do |i|
          if expression =~ /random/
            index = Random.new.rand(results.length)
            result = results.delete_at(index)
          else
            result = results.delete_at(0)
          end
          message = result.title + "\n" + result.uri
          send_message client, data.channel, message
        end
      end
    end
  end
end
