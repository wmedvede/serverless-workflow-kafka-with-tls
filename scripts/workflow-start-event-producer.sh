#!/bin/bash

# Starts a pod in the sonataflow-kafka-example namespace that produces a start_event to start a workflow.

# The kafka version goes hand in hand wit the operator version.
# If the version must be changed at some point, you should probably have to visit the quay.io/strimzi repository.
# You can also visit the produced sonataflow-kafka-cluster-entity-operator Deployment, and see the corresponding image
# there. At the time of writing this example, it was 'quay.io/strimzi/operator@sha256:589c4d63641d9a944462dd682f6e5febe8b38ff55b9253949b061aca16feb154'
# which corresponds to quay.io/strimzi/kafka:0.47.0-kafka-4.0.0
KAFKA_VERSION=quay.io/strimzi/kafka:0.47.0-kafka-4.0.0
KAFKA_BOOTSTRAP_SERVERS=sonataflow-kafka-cluster-kafka-bootstrap.sonataflow-kafka.svc.cluster.local:9092

# If you change, make sure that the event is in one line.
CLOUD_EVENT='{"specversion":"1.0","type":"start_event","source":"","id":"A234-1234-1234","time":"2025-08-11T12:00:00Z","datacontenttype":"application/json","data":{"message":"Start Hello World CloudEvent!"}}'

echo "$CLOUD_EVENT" \
| kubectl run start-event-producer \
    --image=$KAFKA_VERSION \
    --rm -i \
    --restart=Never \
    -- bin/kafka-console-producer.sh \
         --bootstrap-server $KAFKA_BOOTSTRAP_SERVERS \
         --topic start-event
