#!/bin/bash
docker run -ti --rm --network="container:postgrest_test" \
	-v $(pwd)/src:/src postgrestdb_schema_setup
