# rindexer examples

Fine grade `.env` for `docker-compose` around [rindexer](https://rindexer.xyz/) with [eRPC](https://docs.erpc.cloud/) working with redis and rindexer writing on postgres.

## rindexer-erpc-dc
> [!IMPORTANT] 
This stack do not contain eRPC endpoint optimisations or rate limiting, it has a minimal working config.

### To launch rindexer postgres with erpc/redis docker-compose stack.
```sh
cd rindexer-erpc-dc
make start
```

| Service             | Endpoint                            |
|---------------------|-------------------------------------|
| **RPC Endpoint**     | [http://localhost:4000](http://localhost:4000) |
| **Metric Endpoint**  | [http://localhost:4001](http://localhost:4001) |
| **GraphQL API**      | [http://localhost:3001/graphql](http://localhost:3001/graphql) |
| **GraphQL Playground** | [http://localhost:3001/playground](http://localhost:3001/playground) |

### To test the endpoints and db with queries.
```sh
make test-erpc-compose
```

### To stop docker-compose and remove instance and volume to restart fresh.
```sh
make stop
```