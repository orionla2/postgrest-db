#!/bin/bash
docker run -ti --rm --network="container:postgrest_test" -v $(pwd):/src mapleukraine/ymigrate
