# es-whosonfirst-schema

Elasticsearch schemas for Who's On First related indices. Because Elasticsearch is too clever when left to its own devices...

## Caveats

There is nothing to see yet.

## Requirements

* [stream2es](https://github.com/elastic/stream2es) - there is a copy of this in the [bin](bin} directory.


## Tips

### Cloning indices with stream2es

The following examples are to show you what's happening / how to re-index _in principle_ but you will need to adjust them to taste and circumstance:

```
$> ./stream2es es --source http://HOST:9200/whosonfirst --target http://HOST:9200/whosonfirst_20160615
$> curl -XDELETE http://HOST:9200/whosonfirst
$> curl -XPOST http://HOST:9200/_aliases -d '{ "actions": [ { "add": { "alias": "whosonfirst", "index": "whosonfirst_20160615" }} ] }'
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

## Emoji

* https://jolicode.com/blog/search-for-emoji-with-elasticsearch
* https://github.com/jolicode/emoji-search

## See also

* The `prepare_geojson` method in [py-mapzen-whosonfirst-search](https://github.com/whosonfirst/py-mapzen-whosonfirst-search/blob/master/mapzen/whosonfirst/search/__init__.py)
* https://www.elastic.co/blog/changing-mapping-with-zero-downtime
