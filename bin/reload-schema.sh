#!/bin/sh

WHOAMI=`python -c 'import os, sys; print os.path.realpath(sys.argv[1])' $0`

DIR=`dirname $WHOAMI`
PROJECT=`dirname $DIR`

if [ -z "$1" ] ; then
	echo "Usage: reload-schema.sh [spelunker|boundaryissues]"
fi

echo "Deleting index 'whosonfirst'"
curl -s -XDELETE 'http://localhost:9200/whosonfirst' | python -mjson.tool

echo "Creating index 'whosonfirst' from 'schema/mappings.$1.json'"
cat "${PROJECT}/schema/mappings.$1.json" | curl -s -XPUT 'http://localhost:9200/whosonfirst' -d @- | python -mjson.tool
