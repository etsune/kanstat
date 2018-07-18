require 'json'
require 'net/http'
require 'uri'

kanji_rx = /[一-龯]/
chapter_rx = /<div id="novel_honbun" class="novel_view">(?<cont>[\s\S]+?)<\/div>/
search_old_rx = /(?<url>https?:\/\/ncode\.syosetu\.com\/(?<rid>[\w]+)\/)"/
search_rx = /href="https:\/\/ncode\.syosetu\.com\/(?<rid>.+?)\/">(?<name>.+?)<\/a>[\s\S]+?<table>/
chapter_urls_rx = /<a href="(?<ch>\/.+?\/(?<cn>\d*)\/)">.+?<\/a>/

data_dir = File.expand_path("../../data/", __FILE__)
genres = JSON.parse(File.read(File.expand_path("../../result/", __FILE__)+'/genres.json'))

def clean_page (text)
    chapter_tags_rx = /<\/?p.*?>/ 
    br_rx = /<br.+?>/
    text[0][0].gsub(chapter_tags_rx,"").gsub(br_rx,"")
end

genres.each do |gid, _|
    (1..100).each do |page|
        search_url = "http://yomou.syosetu.com/search.php?&order=notorder&notnizi=1&genre=#{gid}&p=#{page}"
        search_page = Net::HTTP.get(URI.parse(search_url)).force_encoding('UTF-8')
        search_page.scan(search_rx).each do |rid, name|
            ranobe_url = "http://ncode.syosetu.com/#{rid}/"
            puts("Reading " + rid)
            #ranobe_url = "http://ncode.syosetu.com/n3244bb/"
            ranobe_page = Net::HTTP.get(URI.parse(ranobe_url)).force_encoding('UTF-8')
            chapter_text = ranobe_page.scan(chapter_rx)

            if chapter_text.to_s.length > 10
                File.write(data_dir+"/#{gid}_#{rid}_1.txt", clean_page(chapter_text))
                next
            end

            ranobe_page.scan(chapter_urls_rx) do |ch_url, cn|
                sleep(2)
                puts("Ch " + cn)
                chapter_url = "http://ncode.syosetu.com" + ch_url
                chapter_page = Net::HTTP.get(URI.parse(chapter_url)).force_encoding('UTF-8')
                chapter_text = chapter_page.scan(chapter_rx)

                if chapter_text.to_s.length > 10
                    File.write(data_dir+"/#{gid}_#{rid}_#{cn}.txt", clean_page(chapter_text))
                end
            end
        end
    end
end

