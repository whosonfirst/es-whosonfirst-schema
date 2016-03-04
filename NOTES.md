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

## Snapshots

First create a directory for storing snapshots (it is also possible to snapshot (and restore) to S3)

```
$> mkdir /usr/local/snapshots
$> sudo chown elasticsearch.elasticsearch /usr/local/snapshots
```

Ensure that the directory is listed in the `path.repo` directive in your `elasticsearch.yml` file, like this:

```
path.repo: ["/usr/local/snapshots"]
```

Then restart your ES server:

```
$> /etc/init.d/elasticsearch restart
```

```
$> curl -XPUT 'http://localhost:9200/_snapshot/whosonfirst' -d '{ "type": "fs", "settings": { "location": "/usr/local/snapshots", "compress": true } }'

{"acknowledged":true}

$> curl -XPUT 'http://localhost:9200/_snapshot/whosonfirst/20160304?wait_for_completion=true'

{"snapshot":{"snapshot":"20160304","version_id":1070199,"version":"1.7.1","indices":["whosonfirst"],"state":"SUCCESS","start_time":"2016-03-04T15:54:24.906Z","start_time_in_millis":1457106864906,"end_time":"2016-03-04T16:01:09.705Z","end_time_in_millis":1457107269705,"duration_in_millis":404799,"failures":[],"shards":{"total":12,"failed":0,"successful":12}}}
```

## See also

* https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-snapshots.html

