#!/bin/bash

# Example of building the image using the Quarkus generated Dockerfile.jvn

REGISTRY_USER=$USER
REGISTRY=quay.io

IMG=$REGISTRY/$USER/serverless-workflow-kafka-with-tls:1.0-00-jvm

docker build -f ./docker/Dockerfile.jvm -t $IMG .

docker push $IMG
