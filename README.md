# es-whosonfirst-schema

Elasticsearch schemas for Who's On First related indices. Because Elasticsearch is too clever when left to its own devices...

## rebuilding an index (in a nutshell)

```
curl -XDELETE http://localhost:9200/spelunker_current
cat schema/mappings.spelunker.json | curl -XPUT http://localhost:9200/spelunker_current -d @-
curl -XPOST http://localhost:9200/_aliases -d '{ "actions": [ { "add": { "alias": "spelunker", "index": "spelunker_current" }} ] }'
```

## dumping an index

```
curl -s 'http://localhost:9200/spelunker_current/_mappings?pretty=on'
```

__A note of caution:__ the format of the dumped index is structured _slightly_ differently than what you use to build the index mappings. The former has a top-level key `[index name]` that contains that `"mappings"` structure. In the latter case, the `"mappings"` appear at the top-level.

## listing current indices

```
curl -s http://localhost:9200/_aliases | python -mjson.tool
{
    "boundaryissues_dphiffer-museums": {
        "aliases": {}
    },
    "boundaryissues_stepps00-test": {
        "aliases": {}
    },
    "boundaryissues_v1": {
        "aliases": {
            "boundaryissues": {}
        }
    },
    "spelunker_20160707": {
        "aliases": {
            "spelunker": {}
        }
    }
}
```

## creating a new index

```
cat schema/mappings.spelunker.json | curl -XPUT http://localhost:9200/spelunker_current -d @-
{"acknowledged":true}
```

_See the `-d @-` at the end of that command? Yeah, that part is important. Trust me..._

Test your new index with

```
curl 'http://localhost:9200/spelunker_current/_mappings?pretty=on' | less
```

If it comes back with something like `mappings: {}` then something is wrong. Do _not_ proceed.

## clone the current index to the new index

```
./bin/stream2es es --source http://localhost:9200/spelunker --target http://localhost:9200/spelunker_current
```

## updating pointers (for indices)

```
curl -XPOST http://localhost:9200/_aliases -d '{ "actions": [ { "add": { "alias": "spelunker", "index": "spelunker_current" }} ] }'
curl -s http://localhost:9200/_aliases | python -mjson.tool
{
    "boundaryissues_dphiffer-museums": {
        "aliases": {}
    },
    "boundaryissues_stepps00-test": {
        "aliases": {}
    },
    "boundaryissues_v1": {
        "aliases": {
            "boundaryissues": {}
        }
    },
    "spelunker_20160707": {
        "aliases": {
            "spelunker": {}
        }
    },
    "spelunker_current": {
        "aliases": {
            "spelunker": {}
        }
    }
}
```

At which point your `spelunker` index will return two of everything so you need to make sure to delete the old alias.

```
curl -XDELETE http://localhost:9200/spelunker_20160707
curl -s http://localhost:9200/_aliases | python -mjson.tool
{
    "boundaryissues_stepps00-test": {
        "aliases": {}
    },
    "boundaryissues_v1": {
        "aliases": {
            "boundaryissues": {}
        }
    },
    "spelunker_current": {
        "aliases": {
            "spelunker": {}
        }
    }
}
```

## Cloning indices with stream2es

The following examples are to show you what's happening / how to re-index _in principle_ but you will need to adjust them to taste and circumstance:

```
$> ./stream2es es --source http://HOST:9200/spelunker --target http://HOST:9200/spelunker_20160615
$> curl -XDELETE http://HOST:9200/spelunker
$> curl -XPOST http://HOST:9200/_aliases -d '{ "actions": [ { "add": { "alias": "spelunker", "index": "spelunker_20160615" }} ] }'
```

There isn't a whole of feedback during the cloning process so the easiest thing to do is ask the new index how big it is, like this:

```
$> curl -s 'http://HOST:9200/INDEX/_search?q=*:*&rows=1' | python -mjson.tool | jq '.hits.total'
9950487
```

Which you can then pipe in to the `watch` command for live updates, like this:

```
$> watch -n 10 "curl -s 'http://HOST:9200/INDEX/_search?q=*:*&rows=1' | python -mjson.tool | jq '.hits.total'"
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

## See also

* The `prepare_geojson` method in [py-mapzen-spelunker-search](https://github.com/spelunker/py-mapzen-spelunker-search/blob/master/mapzen/spelunker/search/__init__.py)
* https://www.elastic.co/blog/changing-mapping-with-zero-downtime