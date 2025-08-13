#!/bin/bash

# Example of building the image using the OSL builder image.

REGISTRY_USER=$USER
REGISTRY=quay.io

IMG=$REGISTRY/$USER/serverless-workflow-kafka-with-tls:1.0-1.36.0-00

# additional extensions to connect with kafka.
QUARKUS_EXTENSIONS=io.quarkus:quarkus-smallrye-reactive-messaging-kafka:3.15.4.redhat-00001

docker build -f ./docker/Dockerfile \
  --build-arg=QUARKUS_EXTENSIONS=$QUARKUS_EXTENSIONS \
  --tag $IMG \
  ./src/main/resources

docker push $IMG
