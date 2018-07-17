require 'net/http'
require 'uri'
require 'json'

# Парсим жанры и генерим JSON result/genres.json
genres = {}
data_dir = File.expand_path("../../result/", __FILE__)

search_url = "http://yomou.syosetu.com/search.php"
search_page = Net::HTTP.get(URI.parse(search_url)).force_encoding('UTF-8')

genres_rx = /<label><input type="checkbox" id=".+?" value="(?<id>\d+)" data-parent="\d*" \/>(?<name>.+?)<\/label>/

search_page.scan(genres_rx).each do |match|
    genres[match[0]] = { "jp"=>match[1], "en"=>match[1], "ru"=>match[1] }
end

File.write(data_dir+"/genres.json", genres.to_json)
puts "Complete."