Short version: I am still wrapping my head around all of this.

Longer version: I spent 30 minutes looking into how the mappings work in ES,
with the assistance of O'Reilly's *Elasticsearch The Definitive Guide* and
managed to update the mappings. Here is a summarized version, to pick up on
later:

```
curl -XGET 'localhost:9200/whosonfirst/_mapping?pretty' -o mapping.json
emacs mapping.json
```

Edit the (very large!) JSON document, and be sure to remove the first container
`whosonfirst` object. It should look like this:

```
{
  "mappings" : {
    "neighbourhood" : {
      "properties" : {
        "edtf:cessation" : {
          "type" : "string"
        },
				...
```

Then delete the existing index, and create a new one based on your JSON file.

```
curl -XDELETE 'http://localhost:9200/whosonfirst'
cat mapping.json | curl -XPUT 'http://localhost:9200/whosonfirst' -d @-
```

Open question: can we add mappings without reindexing the entire datastore?
