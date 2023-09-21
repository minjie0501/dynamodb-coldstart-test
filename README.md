# dynamo coldstart

TypeScript Serverless Boilerplate contains all the boilerplate you need to create a Serverless TypeScript project.

## Prerequisites
* Have docker-compose installed (https://www.docker.com/products/docker-desktop/) and running

## Installation

* Run `./start-project.sh` to setup a database in a docker container
* Run `make setup`

## Development
Make sure you keep in the container CLI for further development and testing, all dependencies are only existing inside the container

### Locally running lambdas

#### Usage of SLS OFFLINE
Run `make sls-offline` so all endpoints are accessible via Postman on http://localhost:3000/

### Tests

* Run `make test` to run the tests
