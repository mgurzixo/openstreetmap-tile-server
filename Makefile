.PHONY: modtile build testinit testload testserve

TEST_DIR=/u2/test
MOD_TILES=/u2/tmp/mod_tile_build/src
IMAGE=tsimage

modtile:
	cd ../mod_tile;sh compile.sh

build:
	cp $(MOD_TILES)/renderd .
	cp $(MOD_TILES)/render_expired .
	cp $(MOD_TILES)/render_list .
	cp $(MOD_TILES)/render_speedtest .
	cp $(MOD_TILES)/mod_tile.so .
	docker build -t $(IMAGE) .

testinit:
	cd $(TEST_DIR); mkdir -p pbf
	cd $(TEST_DIR)/pbf;wget https://download.geofabrik.de/europe/luxembourg-latest.osm.pbf
	cd $(TEST_DIR)/pbf;wget https://download.geofabrik.de/europe/luxembourg.poly

testload:
	sudo rm -fr $(TEST_DIR)/data
	sudo rm -fr $(TEST_DIR)/tiles
	mkdir $(TEST_DIR)/data
	mkdir $(TEST_DIR)/tiles
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

testserve:
	docker run  \
		-p 8081:80 \
		-p 5432:5432 \
		--name testRun \
		-v $(TEST_DIR)/pbf/luxembourg.poly:/data/region.poly \
		-v $(TEST_DIR)/data:/data/database/  \
		-v $(TEST_DIR)/tiles:/data/tiles/  \
		-e THREADS=32 \
		-e UPDATES=enabled \
		-e "FLAT_NODES=disabled" \
		-e ALLOW_CORS=enabled \
		--shm-size="32g" \
		-d $(IMAGE) \
		run

testshell:
	docker exec -it testRun bash
