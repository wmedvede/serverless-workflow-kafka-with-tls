#!/bin/bash

# Starts a pod in the sonataflow-kafka-example namespace that consumes the exit_events produced by the helloworld workflow.
# Nice to see the workflow finishing.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOPIC=exit-event
CONSUMER_NAME=workflow-exit-event-consumer
source "$SCRIPT_DIR/workflow-event-consumer.sh"
