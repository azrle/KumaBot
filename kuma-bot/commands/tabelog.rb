require 'levenshtein'
require 'nokogiri'

module KumaBot
  module Commands
    class Tabelog < SlackRubyBot::Commands::Base
      station_index = Hash.new
      IO.readlines("config/tabelog_area_code").each do |line|
        parts = line.split(/\t/)
        station_index[parts[1].chomp!] = parts[0]
      end

      match(/^kumakun tabelog\s+(?<location>.+?)\s+(?<expression>.+)$/) do |client, data, match|
        location = match['location']
        expression = match['expression'].strip

        # location matched
        if station_index.has_key? location
          keyword = ""
          mode    = "top"
          limit   = 5
          cost    = 0

          # mode
          if expression =~ /--(random|top)(\d+)/
            mode = $1
            limit = $2.to_i if $2.to_i <= 20
          end
          # cost
          if expression =~ /--cost(\d+)/
            cost = ($1.to_f / 1000).ceil.to_i
          end
          # keyword
          if expression =~ /([^\s]+)\s+--/
            keyword = $1
          else
            keyword = expression
          end

          proxy = "117.135.250.136:81"
          # proxy = Proxy.get_proxy(Proxy.fetch_proxy_list("US"))
          station_code = station_index[location]

          # calc max_page of restaurant list
          search_url = "http://tabelog.com/#{station_code}/rstLst/?SrtT=rt&sw=#{keyword}&LstCos=0&LstCosT=#{cost}"
          html = `curl -x #{proxy} '#{search_url}'`

          max_page = 1
          matched = html.match(/店名に.*?全 <span class="text-num fs15"><strong>(\d+)<\/strong><\/span> 件/m)
          unless matched.nil?
            max_page = (matched[1].to_f / 20).ceil.to_i
          end
          matched = html.match(/お店の情報に.*?全 <span class="text-num fs15"><strong>(\d+)<\/strong><\/span> 件/m)
          unless matched.nil?
            max_page = (matched[1].to_f / 20).ceil.to_i if max_page < (matched[1].to_f / 20).ceil.to_i
          end
          max_page = 3 if max_page > 3

          # get restaurant list
          restaurant_links = Array.new
          (1..max_page).each do |page|
            search_url = "http://tabelog.com/#{station_code}/rstLst/#{page}/?SrtT=rt&sw=#{keyword}&LstCosT=#{cost}"
            html = `curl -x #{proxy} '#{search_url}'`
            html.scan(/data-rd-url=".*?(http:\/\/tabelog\.com.+?)" rel="ranking-num"/).each do |url|
              restaurant_links << url[0] unless restaurant_links.include?(url[0])
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
            send_message client, data.channel, "
==========================================================
*#{info["name"]}*
      Genre: #{info["genre"]}
      Rate: #{info["rate"]}
      Address: #{info["addr"]}
      Webpage: #{info["url"]}
            "
          end

        # location doesn't match, but we can guess
        else
          guess = ""
          station_index.keys.each do |l|
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
