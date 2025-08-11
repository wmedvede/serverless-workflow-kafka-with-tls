#!/bin/bash

# Starts a pod in the sonataflow-kafka-example that consumes the start_events sent to the helloworld workflow.
# Useful to sniff these events in cases a third application is producing them.
# No competition with the WF since using a different kafka group id.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOPIC=start-event
CONSUMER_NAME=workflow-start-event-consumer
source "$SCRIPT_DIR/workflow-event-consumer.sh"
