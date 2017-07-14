# es-whosonfirst-schema

Elasticsearch schemas for Who's On First related indices. Because Elasticsearch is too clever when left to its own devices...

## Indexes and aliases

* https://www.elastic.co/guide/en/elasticsearch/reference/2.4/indices-aliases.html

### listing current indices and their aliases

```
curl -s http://localhost:9200/_aliases | python -mjson.tool
{
    "spelunker_20160707": {
        "aliases": {
            "spelunker": {}
        }
    }
}
```

See the way there is an alias to an index called `spelunker` ? That's so everyone can just point to a single index and be done with it.

### creating a new index

Let's say you want to create a new index called `spelunker_20170711` that will replace the `spelunker_20160707` index (and its alias). First create your index:

```
cat schema/2.4/mappings.spelunker.json | curl -XPUT http://localhost:9200/spelunker_20170711 -d @-
{"acknowledged":true}
```

_See the `-d @-` at the end of that command? Yeah, that part is important. Trust me..._

Test your new index with

```
curl 'http://localhost:9200/spelunker_20170711/_mappings?pretty=on' | less
```

_If it comes back with something like `mappings: {}` then something is wrong. Do not proceed._

The details of how you update the contents of your new `spelunker_20170711` index are outside the scope of this document.

### updating aliases (for indices)

Important: Read through the next section in its entirety before you start copy-paste-ing commands all over the place. What is described below will leave open the very real possibility that for some number of requests (for services using the aliased `spelunker` index) duplicate data will be returned. Read that last sentence again. If you don't understand it, then stop and go find someone to help explain it. If you do understand it then take whatever steps are necessary to proceed. This might include "throwing caution to the wind" or "not caring". That's your business. It might be easier just to disable the services or temporarily have then point to the `spelunker_20170711` index and then back to `spelunker` again.

```
curl -X POST http://localhost:9200/_aliases -d '{ "actions": [ { "add": { "alias": "spelunker", "index": "spelunker_20170711" }} ] }'

curl -s http://localhost:9200/_aliases | python -mjson.tool

{
    "spelunker_20160707": {
        "aliases": {
            "spelunker": {}
        }
    },
    "spelunker_20170711": {
        "aliases": {
            "spelunker": {}
        }
    }
}
```

At which point your `spelunker` index will return _two of everything_ so you need to make sure to remove the old alias. See notes above.

```
curl -X POST 'http://localhost:9200/_aliases' -d '{ "actions": [ { "remove": { "alias": "spelunker", "index": "spelunker_20160707" }} ] }'

curl -s http://localhost:9200/_aliases | python -mjson.tool
{
    "spelunker_20170711": {
        "aliases": {
            "spelunker": {}
        }
    }
}
```

You can also remove the entire index (and with it the alias) but you might want to wait until you're sure the new index is working properly before you do that.

```
curl -X DELETE http://localhost:9200/spelunker_20160707
```

### dumping an index

```
curl -s 'http://localhost:9200/spelunker_current/_mappings?pretty=on'
```

__A note of caution:__ the format of the dumped index is structured _slightly_ differently than what you use to build the index mappings. The former has a top-level key `[index name]` that contains that `"mappings"` structure. In the latter case, the `"mappings"` appear at the top-level.

## Cloning indices with stream2es

The following examples are to show you what's happening / how to re-index _in principle_ but you will need to adjust them to taste and circumstance:

```
$> ./stream2es es --source http://localhost:9200/spelunker --target http://localhost:9200/spelunker_20160615

$> curl -X DELETE http://localhost:9200/spelunker

$> curl -X POST http://localhost:9200/_aliases -d '{ "actions": [ { "add": { "alias": "spelunker", "index": "spelunker_20160615" }} ] }'
```

There isn't a whole of feedback during the cloning process so the easiest thing to do is ask the new index how big it is, like this:

```
$> curl -s 'http://localhost:9200/INDEX/_search?q=*:*&rows=1' | python -mjson.tool | jq '.hits.total'
9950487
```

Which you can then pipe in to the `watch` command for live updates, like this:

```
$> watch -n 10 "curl -s 'http://localhost:9200/INDEX/_search?q=*:*&rows=1' | python -mjson.tool | jq '.hits.total'"
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
$> curl -XPUT 'http://localhost:9200/_snapshot/spelunker' -d '{ "type": "fs", "settings": { "location": "/usr/local/snapshots", "compress": true } }'

{"acknowledged":true}

$> curl -XPUT 'http://localhost:9200/_snapshot/spelunker/20160304?wait_for_completion=true'

{"snapshot":{"snapshot":"20160304","version_id":1070199,"version":"1.7.1","indices":["spelunker"],"state":"SUCCESS","start_time":"2016-03-04T15:54:24.906Z","start_time_in_millis":1457106864906,"end_time":"2016-03-04T16:01:09.705Z","end_time_in_millis":1457107269705,"duration_in_millis":404799,"failures":[],"shards":{"total":12,"failed":0,"successful":12}}}
```

## Emoji

![mmmmm....donuts](images/spelunker-spelunker-donut.png)

* https://jolicode.com/blog/search-for-emoji-with-elasticsearch
* https://github.com/jolicode/emoji-search

## Autocomplete

* https://qbox.io/blog/multi-field-partial-word-autocomplete-in-elasticsearch-using-ngrams
* https://jontai.me/blog/2013/02/adding-autocomplete-to-an-elasticsearch-search-application/
* https://gist.github.com/justinvw/5025854
* https://stackoverflow.com/questions/36806081/how-to-query-for-auto-complete-in-elastic-search

### Example

```
curl 'localhost:9200/brands_20170710/_search?pretty=on' -d '{"query": {"match": { "names_autocomplete": "Jack" }}}' | less
```

## Brands

_Please finish writing me..._

```
brands-es-index -s /usr/local/data/whosonfirst-brands/data/ -b --index brands_20170710
```

## See also

* The `prepare_geojson` method in [py-mapzen-spelunker-search](https://github.com/spelunker/py-mapzen-spelunker-search/blob/master/mapzen/spelunker/search/__init__.py)
* https://www.elastic.co/blog/changing-mapping-with-zero-downtime