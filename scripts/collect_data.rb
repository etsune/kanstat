


kanji_rx = /[一-龯]/
chapter_rx = /<div id="novel_honbun" class="novel_view">[\s\S]+?<\/div>/
search_rx = /(?<url>https?:\/\/ncode\.syosetu\.com\/(?<rid>[\w]+)\/)"/

data_dir = File.expand_path("../../data/", __FILE__)
