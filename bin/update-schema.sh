#!/bin/bash

WHOAMI=`python -c 'import os, sys; print os.path.realpath(sys.argv[1])' $0`

DIR=`dirname $WHOAMI`
PROJECT=`dirname $DIR`
INDEX_BASE='whosonfirst'

if [ -z "$1" ] ; then
	echo "Usage: update-schema.sh [spelunker|boundaryissues|offline-tasks]"
	exit 1
fi

if [ "$1" = "spelunker" ] ; then
	INDEX_FILE="SPELUNKER_INDEX_VERSION"
elif [ "$1" = "boundaryissues" ] ; then
	INDEX_FILE="BOUNDARYISSUES_INDEX_VERSION"
elif [ "$1" = "offline-tasks" ] ; then
	INDEX_FILE="OFFLINE_TASKS_INDEX_VERSION"
	INDEX_BASE="offline-tasks"
fi

if [ ! -f "$PROJECT/schema/mappings.$1.json" ] ; then
	echo "Not found: schema/mappings.$1.json"
	exit 1
fi

if [ -f "$PROJECT/$INDEX_FILE" ] ; then
	OLD_VERSION=`cat $PROJECT/$INDEX_FILE`
else
	OLD_VERSION=0
fi

VERSION=$(($OLD_VERSION + 1))
INDEX="${INDEX_BASE}_v$VERSION"
OLD_INDEX="${INDEX_BASE}_v$OLD_VERSION"

echo "Building index $INDEX"
cat "$PROJECT/schema/mappings.$1.json" | curl -s -XPUT "http://localhost:9200/${INDEX}" -d @- | python -mjson.tool

echo "Copying documents to $INDEX"
stream2es es \
	--source http://localhost:9200/${INDEX_BASE} \
	--target http://localhost:9200/${INDEX} \
	--log debug

echo "Updating aliases"
if [ "$OLD_VERSION" -eq 0 ] ; then

	echo "Deleting index $INDEX_BASE"
	curl -s -XDELETE "http://localhost:9200/${INDEX_BASE}" | python -mjson.tool

	echo "Creating alias $INDEX => $INDEX_BASE"
	curl -s -XPOST localhost:9200/_aliases -d '
	{
		"actions": [
			{ "add": {
				"alias": "'${INDEX_BASE}'",
				"index": "'${INDEX}'"
			}}
		]
	}
	' | python -mjson.tool
else

	echo "Reassigning alias $INDEX => $INDEX_BASE"
	curl -s -XPOST localhost:9200/_aliases -d '
	{
		"actions": [
			{ "remove": {
				"alias": "'${INDEX_BASE}'",
				"index": "'${OLD_INDEX}'"
			}},
			{ "add": {
				"alias": "'${INDEX_BASE}'",
				"index": "'${INDEX}'"
			}}
		]
	}
	' | python -mjson.tool

	echo "Deleting index $OLD_INDEX"
	curl -s -XDELETE "http://localhost:9200/${OLD_INDEX}" | python -mjson.tool
fi

echo $VERSION > "$PROJECT/$INDEX_FILE"
