#!/bin/bash

. /usr/sbin/so-common

KISMET_DS=$(cat /tmp/kismet_datasources.json)

# Check for kismet-datasources index
RAW_JSON=$(sudo so-elasticsearch-query kismet-datasources)
NAME=$(jq -r '.["kismet-datasources"].settings.index.provided_name' <<< "$RAW_JSON")

# Create index for kismet-datasources data
echo "Checking if kismet-datasources index exists"
if [ "$NAME" != "kismet-datasources" ]; then
    echo "Creating kismet-datasources index"
    sudo so-elasticsearch-query kismet-datasources -d "{\"settings\": {\"number_of_replicas\": 0 } }" -XPUT | jq -c
else
    echo "kismet-datasources index already exists... "
fi

echo "$KISMET_DS" | jq -c '.[]' | while read -r item; do
    stripped=$(jq -c '{"kismet_datasource_uuid":.["kismet.datasource.uuid"],"kismet_datasource_name":.["kismet.datasource.name"]}' <<< "$item")
    escaped=$(sed 's/"/\\"/g' <<< "$stripped")
    cmd="sudo so-elasticsearch-query kismet-datasources/_doc/ -d \"$escaped\" -XPOST"
    eval $cmd | jq -c
done

#Check if enrich policy exists
echo "Checking if kismet-enrich-policy exists"
ENRICH_JSON=$(sudo so-elasticsearch-query _enrich/policy/kismet-enrich-policy)
ENRICH_NAME=$(jq -r '.policies[].config.match.name' <<< "$ENRICH_JSON")

if [ "$ENRICH_NAME" != "kismet-enrich-policy" ]; then
    echo "Creating kismet-enrich-policy"
    sudo so-elasticsearch-query _enrich/policy/kismet-enrich-policy -d "{\"match\":{\"indices\":\"kismet-datasources\",\"match_field\":\"kismet_datasource_uuid\",\"enrich_fields\":[\"kismet_datasource_name\"]}}" -XPUT | jq -c
    echo "Executing enrich policy for the first time"
    sudo so-elasticsearch-query _enrich/policy/kismet-enrich-policy/_execute -XPUT | jq -c
else
    echo "kismet-enrich-policy already exists..."
    echo "Executing enrich policy for any updated kismet-datasources"
    sudo so-elasticsearch-query _enrich/policy/kismet-enrich-policy/_execute -XPUT | jq -c
fi
