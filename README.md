# es-whosonfirst-schema

Elasticsearch schemas for Who's On First related indices. Because Elasticsearch is too clever when left to its own devices...

## Caveats

There is nothing to see yet.

## Requirements

* [stream2es](https://github.com/elastic/stream2es) - there is a copy of this in the [bin](bin} directory.


## Tips

### Cloning indices with stream2es

There isn't a whole of feedback during the cloning process so the easiest thing to do is ask the new index how big it is, like this:

```
$> curl -s 'http://HOST:9200/INDEX/_search?q=*:*&rows=1' | python -mjson.tool | jq '.hits.total'
9950487
```

Which you can then pipe in to the `watch` command for live updates, like this:

```
$> watch -n 10 "curl -s 'http://HOST:9200/INDEX/_search?q=*:*&rows=1' | python -mjson.tool | jq '.hits.total'"
```

## See also

* The `prepare_geojson` method in [py-mapzen-whosonfirst-search](https://github.com/whosonfirst/py-mapzen-whosonfirst-search/blob/master/mapzen/whosonfirst/search/__init__.py)
* https://www.elastic.co/blog/changing-mapping-with-zero-downtime
