require 'levenshtein'
require 'nokogiri'

module KumaBot
  module Commands
    class Tabelog < SlackRubyBot::Commands::Base
      index = Hash.new
      IO.readlines("config/tabelog_area_code").each do |line|
        parts = line.split(/\t/)
        index[parts[1].chomp!] = parts[0]
      end

      match(/^kumakun tabelog\s+(?<location>.+?)\s+(?<expression>.+)$/) do |client, data, match|
        location = match['location']
        expression = match['expression'].strip

        # location matched
        if index.has_key? location
          mode = "top"
          limit = 5
          if expression =~ /(.+)\s+--(random|top)(\d+)/
            query = $1
            mode = $2
            limit = $3.to_i if $3.to_i <= 20
          else
            query = expression
          end

          proxy = "117.135.250.136:81"
          # proxy = Proxy.get_proxy(Proxy.fetch_proxy_list("US"))
          station_code = index[location]

          # calc max_page of restaurant list
          search_url = "http://tabelog.com/#{station_code}/rstLst/1/?SrtT=rt&sw=#{query}"
          html = `curl -x #{proxy} '#{search_url}'`
          if html =~ /全 <span class="text-num fs15"><strong>(\d+)<\/strong><\/span> 件/
            if $1.to_i > 180
              max_page = 10
            else
              max_page = ($1.to_f / 20).ceil
            end
          end

          # get restaurant list
          restaurant_links = Array.new
          (1..max_page.to_i).each do |page|
            search_url = "http://tabelog.com/#{station_code}/rstLst/#{page}/?SrtT=rt&sw=#{query}"
            html = `curl -x #{proxy} '#{search_url}'`
            html.scan(/data-rd-url=".*?(http:\/\/tabelog\.com.+?)" rel="ranking-num"/).each do |url|
              restaurant_links << url[0]
            end
          end

          # choose
          (1..limit).each do |i|
            idx = 0
            case mode
            when "random"
              idx = Random.new.rand(restaurant_links.length)
            when "top"
              idx = 0
            end
            url = restaurant_links.delete_at(idx)
            info = parse_url(url, proxy)
            send_message client, data.channel, "*#{info["name"]}*\nGenre: #{info["genre"]}\nRate: #{info["rate"]}\nAddress: #{info["addr"]}\nWebpage: #{info["url"]}"
          end

        # location doesn't match, but we can guess
        else
          guess = ""
          index.keys.each do |l|
            if Levenshtein.normalized_distance(l, location) <= 0.3 || l.match(location)
              guess += "#{l}\n"
            end
          end
          send_message client, data.channel, "Maybe you mean...\n```#{guess}```"
        end
      end

      def self.parse_url(url, proxy)
        html = `curl -x #{proxy} '#{url}'`
        document = Nokogiri::HTML(html)
        table = document.css("#contents-rstdata table.rst-data").first
        nodes = table.css("tr")
        {
          "name"  => nodes[0].css("strong").inner_text,
          "genre" => nodes[1].css("p").inner_text,
          "rate"  => document.at("meta[property='og:description']")['content'],
          "addr"  => nodes[3].css("p").first.inner_text,
          "url"   => url,
        }
      end

    end
  end
end
