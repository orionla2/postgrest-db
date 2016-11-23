#!/bin/sh
echo $POSTGRES_USER
echo $POSTGRES_PASSWORD
echo $POSTGRES_DB
# usage create_schema.sh <schema name> <sql file with schema creation commands>
if !(psql -U $POSTGRES_USER -a -c "select schema_name from information_schema.schemata"|grep -q $1) 
then
  psql -U $POSTGRES_USER -a -f $2 
else
  echo "schema already exists, nothing to do"
fi