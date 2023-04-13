# Kafka Docker

Docker compose file to setup local Kafka and schema registry. Kafka instance uses SASL SSL for security.

## Instructions

1. Generate certs
```
./generate-certs.sh
```

2. Launch containers
```
docker-compose up
```
