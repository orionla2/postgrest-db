#!/bin/sh
echo $POSTGRES_USER
echo $POSTGRES_PASSWORD
echo $POSTGRES_DB
echo $PGHOST
echo SCHEMA RUN
cd /schema
wfi/wait-for-it.sh target_service:5432 -s -t 600  -- ./create_schema.sh my_yacht db.sql