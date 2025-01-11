.PHONY: modtile build testinit testload testserve

TEST_DIR=/u/test
WORLD_DIR=/u/world
WORLD_CACHE=/world2/tiles
MOD_TILES=/u/tmp/mod_tile_build/src
O2P=../osm2pgsql
IMAGE=mgtileserver

modtile:
	cd ../mod_tile;sh compile.sh

# https://github.com/osm2pgsql-dev/osm2pgsql
osm2pgsql:
	cd $(O2P)/build; make

build:
	cp $(MOD_TILES)/renderd .
	cp $(MOD_TILES)/render_expired .
	cp $(MOD_TILES)/render_list .
	cp $(MOD_TILES)/render_speedtest .
	cp $(MOD_TILES)/mod_tile.so .
	cp $(O2P)/build/osm2pgsql .
	cp $(O2P)/scripts/osm2pgsql-replication .
	cp $(O2P)/default.style .
	cp $(O2P)/empty.style .
	docker build -t $(IMAGE) .

testinit:
	cd $(TEST_DIR); mkdir -p pbf
	cd $(TEST_DIR)/pbf;wget https://download.geofabrik.de/europe/luxembourg-latest.osm.pbf
	cd $(TEST_DIR)/pbf;wget https://download.geofabrik.de/europe/luxembourg.poly

worldinit:
	cd $(WORLD_DIR); mkdir -p pbf
	cd $(WORLD_DIR)/pbf;wget -c http://planet.openstreetmap.org/pbf/planet-latest.osm.pbf

testload:
	sudo rm -fr $(TEST_DIR)/data
	sudo rm -fr $(TEST_DIR)/tiles
	mkdir $(TEST_DIR)/data
	mkdir $(TEST_DIR)/tiles
	- docker rm testLoad
	docker run  \
		--name testLoad \
		-v $(TEST_DIR)/pbf/luxembourg-latest.osm.pbf:/data/region.osm.pbf  \
		-v $(TEST_DIR)/pbf/luxembourg.poly:/data/region.poly \
		-v $(TEST_DIR)/data:/data/database/  \
		-v $(TEST_DIR)/tiles:/data/tiles/  \
		-e UPDATES=enabled \
		-e "FLAT_NODES=disabled" \
		-e THREADS=32 \
		-e "OSM2PGSQL_EXTRA_ARGS=-C 32000" \
		-e AUTOVACUUM=off \
		--shm-size="32g" \
		$(IMAGE) \
		import

worldload:
	sudo rm -fr $(WORLD_DIR)/data
	sudo rm -fr $(WORLD_DIR)/tiles
	mkdir -p $(WORLD_DIR)/data
	mkdir -p $(WORLD_DIR)/tiles
	docker run  \
		--name worldLoad2 \
		-v $(WORLD_DIR)/pbf/planet-latest.osm.pbf:/data/region.osm.pbf  \
		-v $(WORLD_DIR)/data:/data/database/  \
		-v $(WORLD_DIR)/tiles:/data/tiles/  \
		-e UPDATES=enabled \
		-e "FLAT_NODES=enabled" \
		-e THREADS=32 \
		-e "OSM2PGSQL_EXTRA_ARGS=-C 32000" \
		-e AUTOVACUUM=off \
		--shm-size="32g" \
		$(IMAGE) \
		import

testserve:
	docker run  \
		-p 8081:80 \
		-p 15432:5432 \
		--name testServe \
		-v $(TEST_DIR)/pbf/luxembourg.poly:/data/region.poly \
		-v $(TEST_DIR)/data:/data/database/  \
		-v $(TEST_DIR)/tiles:/data/tiles/  \
		-e THREADS=16 \
		-e UPDATES=enabled \
		-e "FLAT_NODES=disabled" \
		-e ALLOW_CORS=enabled \
		--shm-size="16g" \
		-d $(IMAGE) \
		run

worldserve:
	docker run  \
		-p 8083:80 \
		-p 35432:5432 \
		--name worldServe2 \
		-v $(WORLD_DIR)/data:/data/database/  \
		-v $(WORLD_CACHE):/data/tiles/  \
		-e THREADS=16 \
		-e UPDATES=enabled \
		-e "FLAT_NODES=enabled" \
		-e ALLOW_CORS=enabled \
		--shm-size="16g" \
		-d $(IMAGE) \
		run

worldcache:
	render_list -a -l 16 -n 8 -Z 14

testshell:
	docker exec -it worldServe2 bash
