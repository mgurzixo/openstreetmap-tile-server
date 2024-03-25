#!/bin/sh
docker run  \
--name zambiaLoad \
  -v /u2/pbf/zambia-latest.osm.pbf:/data/region.osm.pbf  \
  -v /u2/pbf/zambia.poly:/data/region.poly \
  -v /u2/data-zambia:/data/database/  \
  -v /u2/tiles:/data/tiles/  \
  -e UPDATES=enabled \
  -e THREADS=16 \
  -e "OSM2PGSQL_EXTRA_ARGS=-C 32000" \
  -e AUTOVACUUM=off \
  --shm-size="192m" \
  overv/openstreetmap-tile-server \
  import

# add for world
#  -e "FLAT_NODES=enabled" \
