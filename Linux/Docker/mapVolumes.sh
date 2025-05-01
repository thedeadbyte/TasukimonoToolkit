#!/bin/bash
echo -e "CONTAINER\tVOLUME\tMOUNTPOINT"
for container in $(docker ps -q); do
  name=$(docker inspect --format='{{.Name}}' $container | cut -c2-)
  docker inspect $container | jq -r '
    .[0].Mounts[] | select(.Type=="volume") |
    "'"$name"'\t\(.Name)\t\(.Destination)"
  '
done
