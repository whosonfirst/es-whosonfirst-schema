emoji:
	curl -s -o synonyms/cldr-emoji-annotation-synonyms-en.txt https://raw.githubusercontent.com/whosonfirst/emoji-search/master/cldr-emoji-annotation-synonyms-en.txt

aliases:
	echo curl -s http://localhost:9200/_aliases | python -mjson.tool

add-index:
	echo "cat schema/2.4/mappings.spelunker.json | curl -XPUT http://localhost:9200/{INDEX} -d @-"

rm-index:
	echo curl -X DELETE http://localhost:9200/{INDEX}

dump-index:
	echo curl -s "http://localhost:9200/{INDEX}/_mappings?pretty=on"

add-alias:
	echo curl -X POST http://localhost:9200/_aliases -d '{ "actions": [ { "add": { "alias": "{ALIAS}", "index": "{INDEX}" }} ] }'

rm-alias:
	echo curl -X POST http://localhost:9200/_aliases -d '{ "actions": [ { "remove": { "alias": "{ALIAS}", "index": "{INDEX}" }} ] }'
