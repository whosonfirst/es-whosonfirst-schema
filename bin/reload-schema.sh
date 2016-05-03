#!/bin/sh

WHOAMI=`python -c 'import os, sys; print os.path.realpath(sys.argv[1])' $0`

DIR=`dirname $WHOAMI`
PROJECT=`dirname $DIR`
INDEX='whosonfirst'

if [ -z "$1" ] ; then
	echo "Usage: reload-schema.sh [spelunker|boundaryissues|offline-tasks]"
fi

if [ "$1" = 'offline_tasks' ] ; then
	INDEX='offline_tasks'
fi

echo "Deleting index '$INDEX'"
curl -s -XDELETE "http://localhost:9200/$INDEX" | python -mjson.tool

echo "Creating index '$INDEX' from 'schema/mappings.$1.json'"
cat "${PROJECT}/schema/mappings.$1.json" | curl -s -XPUT "http://localhost:9200/$INDEX" -d @- | python -mjson.tool
