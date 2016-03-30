#!/bin/bash

WHOAMI=`python -c 'import os, sys; print os.path.realpath(sys.argv[1])' $0`

DIR=`dirname $WHOAMI`
PROJECT=`dirname $DIR`

if [ -z "$1" ] ; then
	echo "Usage: update-schema.sh [spelunker|boundaryissues]"
	exit 0
fi

if [ $1 == "spelunker" ] ; then
	INDEX_FILE="SPELUNKER_INDEX_VERSION"
else
	INDEX_FILE="BOUNDARYISSUES_INDEX_VERSION"
fi

if [ -f "$DIR/../${INDEX_FILE}" ] ; then
	OLD_VERSION=`cat $DIR/../${INDEX_FILE}`
else
	OLD_VERSION=0
fi

VERSION=$(($OLD_VERSION + 1))
INDEX="whosonfirst_v$VERSION"
OLD_INDEX="whosonfirst_v$OLD_VERSION"

echo "Building index $INDEX"
cat "${PROJECT}/schema/mappings.$1.json" | curl -s -XPUT "http://localhost:9200/${INDEX}" -d @- | python -mjson.tool

echo "Copying documents to $INDEX"
${DIR}/stream2es es \
	--source http://localhost:9200/whosonfirst \
	--target http://localhost:9200/${INDEX}

echo "Updating aliases"
if [ "$OLD_VERSION" -eq 0 ] ; then
	curl -s -XPOST localhost:9200/_aliases -d '
	{
		"actions": [
			{ "add": {
				"alias": "whosonfirst",
				"index": "'${INDEX}'"
			}}
		]
	}
	' | python -mjson.tool
else
	curl -s -XPOST localhost:9200/_aliases -d '
	{
		"actions": [
			{ "remove": {
				"alias": "whosonfirst",
				"index": "'${OLD_INDEX}'"
			}},
			{ "add": {
				"alias": "whosonfirst",
				"index": "'${INDEX}'"
			}}
		]
	}
	' | python -mjson.tool

	echo "Deleting index $OLD_INDEX"
	curl -s -XDELETE "http://localhost:9200/${OLD_INDEX}" | python -mjson.tool
fi

echo $VERSION > $INDEX_FILE
