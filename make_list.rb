#!/usr/bin/ruby

require 'yaml'
require 'openssl'
require 'net/http'

def query(start_date, end_date, id)
  bD = start_date.day
  bMn = start_date.month
  bYr = start_date.year
  eD = end_date.day
  eMn = end_date.month
  eYr = end_date.year
  "bD=#{bD}&bMn=#{bMn}&bYr=#{bYr}&Bt=%CF%EE%E8%F1%EA&eD=#{eD}&eMn=#{eMn}&eYr=#{eYr}&Empl=#{id}&Period=0&RG=2"
end

CONFIG_FILE = "config.yml"
OUTPUT_FILE = "list.html"
File.open(CONFIG_FILE) do |f|
  @config = YAML::load(f)
end

File.open(OUTPUT_FILE, "w") do |file|
  file.puts("<ul style='list-style: none;'>")
end

start_date = @config['start_date'] && Date.parse(@config['start_date']) || Date.new
end_date = @config['end_date'] && Date.parse(@config['end_date']) || start_date

range = (@config['from']..@config['to'])
range.each do |id|
  uri = URI("#{@config['secret_url']}?#{query(start_date, end_date, id)}")

  Net::HTTP.start(uri.host, uri.port,
                  use_ssl: uri.scheme == 'https',
                  verify_mode: OpenSSL::SSL::VERIFY_NONE) do |http|

    request = Net::HTTP::Get.new uri.request_uri
    request.basic_auth(@config['login'], @config['password'])
    request.add_field("Cookie", "ASPSESSIONIDQCSADABD=#{@config['aspsessionidqcsadabd']}")

    response = http.request request

    puts "#{id} #{response.inspect}"
    body = response.body
    a = body.match(/<a href=\.\.\/misc\/PersInfo\.asp\?ID=#{id}>(.*)<\/a>/)
    li = unless a.nil?
           "<li>#{id} &rarr; <a href='#{uri}'>#{a[1]}</a></li>"
         else
           "<li><del>#{id}</del></li>"
         end
    File.open(OUTPUT_FILE, "a+") do |file|
      file.puts(li)
    end

    delay = @config['delay']
    if @config['random_delay'] == true
      delay = delay / 2 + Random.new.rand(delay)
    end
    puts "Sleeping #{delay} sec"
    sleep delay
  end
end

File.open(OUTPUT_FILE, "a+") do |file|
  file.puts("</ul>")
end
