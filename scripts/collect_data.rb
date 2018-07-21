require 'json'
require 'net/http'
require 'uri'

kanji_rx = /[一-龯]/ # c >= '\u{4E00}' && c <= '\u{9FD5}'
chapter_rx = /<div id="novel_honbun" class="novel_view">(?<cont>[\s\S]+?)<\/div>/
search_old_rx = /(?<url>https?:\/\/ncode\.syosetu\.com\/(?<rid>[\w]+)\/)"/
search_rx = /href="https:\/\/ncode\.syosetu\.com\/(?<rid>.+?)\/">(?<name>.+?)<\/a>[\s\S]+?<table>/
chapter_urls_rx = /<a href="(?<ch>\/.+?\/(?<cn>\d*)\/)">.+?<\/a>/

# Директория для скачивания ранобэ
$data_dir = File.expand_path("../../data/", __FILE__)

$tmp_dir = File.expand_path("../../tmp/", __FILE__)

# Получаем список жанров
$genres = JSON.parse(File.read(File.expand_path("../../result/", __FILE__) + '/genres.json'))

$data_list_file = $tmp_dir + '/data_list.txt'

# Удалить все сторонние теги из главы
def clean_page (text)
    chapter_tags_rx = /<\/?p.*?>/ 
    br_rx = /<br.+?>/
    text[0][0].gsub(chapter_tags_rx,"").gsub(br_rx,"")
end

# Проверяем, сохраняли ли это ранобэ ранее
def is_id_saved (id)
    begin
        file = File.new($data_list_file, "r")
        while (line = file.gets)
            if line.include?(id)
                file.close
                return true
            end
        end
        file.close
    rescue => err
        puts "Exception: #{err}"
        err
    end
    return false
end

# Составить список ID скачанных глав
def generate_data_list ()
    open($data_list_file, 'a') do |f|
        id_list = Dir[$data_dir+"/*"].map {|i| i.match(/_(?<f>[\w]+?)_\d+?\.txt\z/i)["f"]}
        id_list.uniq.each do |id|
            f.puts id
        end
    end
end

# Начало программы
Dir.mkdir($data_dir) unless Dir.exist?($data_dir)
Dir.mkdir($tmp_dir) unless Dir.exist?($tmp_dir)
File.delete($data_list_file) if File.exist?($data_list_file)
generate_data_list()

# Бесконечное сканирование
loop do

    # Поиск по каждому жанру по очереди
    $genres.each do |gid, _|

        # Считает количество скачанных тайтлов для данного жанра
        getted = 0
        puts("Selected genre #{gid}")
        
        # Перебор страниц поиска
        (1..100).each do |page|

            # После каждых 10 тайтлов переходить к следующему жанру
            # Задержка 1 сек для избежания блокировки (она есть, проверено)
            break if getted > 10
            sleep(1)
            search_url = "http://yomou.syosetu.com/search.php?&order=notorder&notnizi=1&genre=#{gid}&p=#{page}"
            search_page = Net::HTTP.get(URI.parse(search_url)).force_encoding('UTF-8')
            search_page.scan(search_rx).each do |rid, name|
                if is_id_saved(rid)
                    puts "Skip #{rid}"
                    next
                end
                getted += 1
                ranobe_url = "http://ncode.syosetu.com/#{rid}/"
                puts()
                puts("Reading " + rid)
                #ranobe_url = "http://ncode.syosetu.com/n3244bb/"
                ranobe_page = Net::HTTP.get(URI.parse(ranobe_url)).force_encoding('UTF-8')
                chapter_text = ranobe_page.scan(chapter_rx)

                # Сохраняем ранобе из 1 главы или идём дальше, если глав больше
                if chapter_text.to_s.length > 10
                    File.write($data_dir+"/#{gid}_#{rid}_1.txt", clean_page(chapter_text))
                    puts("1")
                    next
                end

                # ch_url - адрес главы
                # cn - номер главы
                ranobe_page.scan(chapter_urls_rx) do |ch_url, cn|
                    sleep(1)
                    print(cn+"-")
                    chapter_url = "http://ncode.syosetu.com" + ch_url
                    chapter_page = Net::HTTP.get(URI.parse(chapter_url)).force_encoding('UTF-8')
                    chapter_text = chapter_page.scan(chapter_rx)

                    if chapter_text.to_s.length > 10
                        saved_file_name = "#{gid}_#{rid}_#{cn}"
                        File.write($data_dir+"/#{saved_file_name}.txt", clean_page(chapter_text))

                        next if Integer(cn) > 1
                        open($data_list_file, 'a') do |f|
                            f.puts saved_file_name
                        end
                    end
                end
                puts()
            end
        end
    end
end

