#!/bin/sh

WHOAMI=`python -c 'import os, sys; print os.path.realpath(sys.argv[1])' $0`

DIR=`dirname $WHOAMI`
PROJECT=`dirname $DIR`

echo "Deleting index 'whosonfirst'"
curl -s -XDELETE 'http://localhost:9200/whosonfirst' | python -mjson.tool

echo "Creating index 'whosonfirst' from 'schema/mappings.json'"
cat "${PROJECT}/schema/mappings.json" | curl -s -XPUT 'http://localhost:9200/whosonfirst' -d @- | python -mjson.tool
