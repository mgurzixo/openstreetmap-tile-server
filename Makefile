.PHONY: build push test

MOD_TILES=/u2/tmp/mod_tile_build/src

testbuild:
	cp $(MOD_TILES)/renderd .
	cp $(MOD_TILES)/render_expired .
	cp $(MOD_TILES)/render_list .
	cp $(MOD_TILES)/render_speedtest .
	cp $(MOD_TILES)/mod_tile.so .
	docker build -t testimage .

testinit:
	cd /u2/pbf;wget https://download.geofabrik.de/europe/luxembourg-latest.osm.pbf
	cd /u2/pbf;wget https://download.geofabrik.de/europe/luxembourg.poly

testload:
	sudo rm -fr /u2/data-test/*
	sudo rm -fr /u2/tiles-test/*
	docker run  \
	--name testLoad \
	-v /u2/pbf/luxembourg-latest.osm.pbf:/data/region.osm.pbf  \
	-v /u2/pbf/luxembourg.poly:/data/region.poly \
	-v /u2/data-test:/data/database/  \
	-v /u2/tiles-test:/data/tiles-test/  \
	-e UPDATES=disabled \
	-e "FLAT_NODES=disabled" \
	-e THREADS=16 \
	-e "OSM2PGSQL_EXTRA_ARGS=-C 32000" \
	-e AUTOVACUUM=off \
	--shm-size="32g" \
	testimage \
	import

testserve:
	docker run  \
	-p 8081:80 \
	-p 5432:5432 \
	--name testRun \
	-v /u2/pbf/luxembourg.poly:/data/region.poly \
	-v /u2/data-test:/data/database/  \
	-v /u2/tiles-test:/data/tiles/  \
	-e THREADS=16 \
	-e UPDATES=disabled \
	-e "FLAT_NODES=disabled" \
	-e ALLOW_CORS=enabled \
	--shm-size="32g" \
	-d testimage \
	run

testshell:
	docker exec -it testRun bash

# apt-get install python3-certbot-dns-cloudflare

certbot:
	certbot certonly --dns-cloudflare --dns-cloudflare-credentials /root/.secrets/certbot/cloudflare.ini -d tile.zonkod.org -d tile.zonkod.com  -d tile0.zonkod.com -d tile1.zonkod.com -d tile2.zonkod.com -d tile3.zonkod.com -d tile4.zonkod.com -d tile5.zonkod.com -d tile6.zonkod.com -d tile7.zonkod.com --preferred-challenges dns-01 --dns-cloudflare-propagation-seconds 20

