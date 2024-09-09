#!/bin/bash

# This script will work if launched from the Makefile in the root of the repository.
# As it uses the environment variables set in the Makefile.
# It will make requests to the eRPC server and the Rindexer GraphQL server.

eRPC_MAINNET=http://${ERPC_HOST}:${ERPC_PORT}/main/evm/1

make_request() {
    local description=$1
    local curl_command=$2
    
    echo "Making request: $description"
    response=$(eval "$curl_command")

    if command -v jq > /dev/null; then
        echo "Response (formatted with jq):"
        echo "$response" | jq .
    else
        echo "Response:"
        echo "$response"
    fi
    echo ""
}

curl_cmd_1="curl -L '${eRPC_MAINNET}' \
-H 'Content-Type: application/json' \
-d '{
    \"method\": \"eth_getBlockByNumber\",
    \"params\": [
        \"0x1203319\",
        false
    ],
    \"id\": 42,
    \"jsonrpc\": \"2.0\"
}'"

curl_cmd_2="curl -L '${eRPC_MAINNET}' \
-H 'Content-Type: application/json' \
-d '{
    \"method\": \"eth_blockNumber\",
    \"params\": [],
    \"id\": 69,
    \"jsonrpc\": \"2.0\"
}'"

curl_cmd_3="curl -X POST 'http://localhost:3001/graphql' \
-H 'Content-Type: application/json' \
-d '{\"query\": \"query LastThreeTransfers { allTransfers(last: 3) { nodes { from to value nodeId } } }\"}'"

make_request "eth_getBlockByNumber" "$curl_cmd_1"
echo "Waiting for 2 seconds..."
sleep 2

make_request "eth_blockNumber" "$curl_cmd_2"
echo "Waiting for 2 seconds..."
sleep 2

make_request "GraphQL LastThreeTransfers query" "$curl_cmd_3"

# Check if 'cast' is installed
if command -v cast > /dev/null; then
    echo "Making request: CAST_BALNCE"
    CAST_BALNCE=$(cast balance --rpc-url ${eRPC_MAINNET} \
        0xf70ba855e8aadbcfafc5118646feda3913bf7217 \
        -e)
    echo "CAST_BALNCE for 0xf70b...7217: $CAST_BALNCE ETH\n"
fi

echo "Making request to metrics endpoint"
monit_res=$(curl -s http://${ERPC_HOST}:${ERPC_METRICS_PORT}/)
echo "$monit_res" | head -n 2
echo "..."
echo "$monit_res" | tail -n 3
echo ""

# Check if the Redis container is running and operating correctly.
echo "Checking the Redis connection..."

if docker exec "$DCKR_REDIS_NAME" redis-cli -a "$REDIS_PASSWORD" ping 2>/dev/null | grep -q "PONG"; then
    echo "-> PONG - Redis is up and running with authentication."
else
    echo "-> Failed to connect to Redis or received unexpected response."
    exit 1
fi

docker exec "$DCKR_REDIS_NAME" redis-cli -a "$REDIS_PASSWORD" set testkey "testvalue" > /dev/null 2>&1
VALUE=$(docker exec "$DCKR_REDIS_NAME" redis-cli -a "$REDIS_PASSWORD" get testkey 2>/dev/null)

if [ "$VALUE" == "testvalue" ]; then
    echo "-> $VALUE - Redis is working. Test key-value pair set and retrieved successfully."
else
    echo "-> Failed to set or retrieve key-value pair in Redis."
    exit 1
fi

echo ""

# Query to check the number of entries in the approval table
QUERY="
SELECT
  'approval' AS table_name,
  COUNT(*) AS row_count
FROM
  rindexererpctest_rocket_pool_eth.approval
UNION ALL
SELECT
  'transfer' AS table_name,
  COUNT(*) AS row_count
FROM
  rindexererpctest_rocket_pool_eth.transfer;
"

echo "Checking the number of entries in tables..."

if ! command -v psql > /dev/null 2>&1; then
    echo "psql command not found. Can't run the query."
    exit 1
else
    # Run the query
    PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$PSQL_HOST" -p "$PSQL_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "$QUERY"
    
    if [ $? -eq 0 ]; then
        echo "Query executed successfully."
    else
        echo "Failed to execute query."
        exit 1
    fi
fi

echo ""
echo "All requests completed."
