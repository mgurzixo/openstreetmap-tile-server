#!/bin/sh
# http://localhost:9444/ui
docker run \
--name s3Tiles \
-p 9444:9000 \
-v /u2/s3Storage:/home/sirius/data \
scireum/s3-ninja:latest
