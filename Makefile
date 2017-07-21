emoji:
	curl -s -o synonyms/cldr-emoji-annotation-synonyms-en.txt https://raw.githubusercontent.com/whosonfirst/emoji-search/master/cldr-emoji-annotation-synonyms-en.txt

aliases:
	curl -s http://localhost:9200/_aliases | python -mjson.tool
