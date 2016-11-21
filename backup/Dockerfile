FROM suzel/docker-postgrest:latest

CMD sleep 3 && exec postgrest postgres://${POSTGREST_DBUSER}:${POSTGREST_DBPASS}@${POSTGREST_DBHOST}:${POSTGREST_DBPORT}/${POSTGREST_DBNAME} \
        --port 3000 \
        --schema ${POSTGREST_SCHEMA} \
        --anonymous ${POSTGREST_ANONYMOUS} \
        --pool ${POSTGREST_POOL} \
        --jwt-secret ${POSTGREST_JWT_SECRET} \
        --max-rows ${POSTGREST_MAX_ROWS}


