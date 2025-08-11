#!/bin/bash

# The kafka version goes hand in hand wit the operator version.
# If the version must be changed at some point, you should probably have to visit the quay.io/strimzi repository.
# You can also visit the produced sonataflow-kafka-cluster-entity-operator Deployment, and see the corresponding image
# there. At the time of writing this example, it was 'quay.io/strimzi/operator@sha256:589c4d63641d9a944462dd682f6e5febe8b38ff55b9253949b061aca16feb154'
# which corresponds to quay.io/strimzi/kafka:0.47.0-kafka-4.0.0
KAFKA_VERSION=quay.io/strimzi/kafka:0.47.0-kafka-4.0.0
KAFKA_BOOTSTRAP_SERVERS=sonataflow-kafka-cluster-kafka-bootstrap.sonataflow-kafka.svc.cluster.local:9092
GROUP_ID=workflow-events-consumer-group
# TOPIC expected to be set by the caller.
oc run $CONSUMER_NAME -ti --rm -n sonataflow-kafka-example \
  --image=$KAFKA_VERSION --restart=Never \
  --command -- /bin/sh -c \
  "bin/kafka-console-consumer.sh \
    --bootstrap-server $KAFKA_BOOTSTRAP_SERVERS \
    --topic $TOPIC \
    --group $GROUP_ID \
    --from-beginning"
