# microservices-monorepo

Heavy scenario example for envctr.

Services: api-gateway, auth-service, user-service,
product-service, order-service, notification-service

## Usage

```bash
envctr -t -b docker -p ./examples/microservices-monorepo
```

In this simplified example, `-b docker` only records backend intent; Docker is not required and changing `-b` only changes metadata.
