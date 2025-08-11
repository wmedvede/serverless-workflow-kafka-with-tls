# Kogito Serverless Workflow Kafka with TLS

This example shows how to configure a workflow to use the Kafka + TLS to receive and deliver the workflow business events,
at the time it's linked with Data Index and Jobs Service supporting services via the OSL Operator.

## Kafka Infrastructure Initialization

To provision the Kafka Strimzi infrastructure for the example follow this steps.

1. Install the Kafka Strimzi Community Operator 0.47.0

Install the Kafka Strimzi Operator using your preferred method.

2. Create the Kafka Cluster

To create the Kafka Cluster execute these commands:

````
oc create namespace sonataflow-kafka
````

````
oc apply -f kubernetes/sonataflow-kafka.yaml -n sonataflow-kafka
````

Give some time to the Kafka Cluster to start, you can verify that the pods are ready with this command.

````
oc get pods -n sonataflow-kafka -l strimzi.io/cluster=sonataflow-kafka-cluster
````

Create the KafkaUser
````
oc apply -f kubernetes/sonataflow-kafka-user.yaml -n sonataflow-kafka
````

3. Generate the `kafka-client-truststore.yaml` to configure the workflow kafka connectors authentication.

To create the truststore execute the following command: 

````
# 1. get the kafka cluser sonataflow-kafka-cluster-cluster-ca-cert
# 2. import into the file /tmp/kafka.truststore.p12 key store  
# 3. produce the Secret kubernetes/kafka-client-truststore.yaml
# 4. delete the file /tmp/kafka.truststore.p12 key store
````
````
oc get secret sonataflow-kafka-cluster-cluster-ca-cert \
-o jsonpath='{.data.ca\.crt}' -n sonataflow-kafka | base64 -d | \
keytool -importcert \
-alias kafka-cluster-ca \
-keystore /tmp/kafka.truststore.p12 \
-storetype PKCS12 \
-storepass kafka-pass -noprompt && \
oc create secret generic kafka-client-truststore \
--from-file=kafka.truststore.p12=/tmp/kafka.truststore.p12 \
--from-literal=truststore-password=kafka-pass \
--dry-run=client -o yaml > kubernetes/kafka-client-truststore.yaml && \
rm /tmp/kafka.truststore.p12
````

> **NOTE:** After the command is executed you'll see the following generated file: `kubernetes/kafka-client-truststore.yaml` containing the truststore.
>
> In situations of a command failure, you might need to delete the file `/tmp/kafka.truststore.p12` to execute the command again.

5. Generate the `kafka-client-keystore.yaml` to configure the workflow kafka connectors authentication.

To create the keystore execute the following command:

````
# 1. Extract the KafkaUser certificate crated by the Kafka Cluster
# 2. Dump it into the file kubernetes/kafka-client-keystore.yaml
````
````
oc get secret sonataflow-kafka-user -n sonataflow-kafka -o json \
| jq '{apiVersion:"v1", kind:"Secret", metadata:{name:"kafka-client-keystore"}, type:.type, data:.data}' > kubernetes/kafka-client-keystore.yaml
````

> **NOTE:** After the command is executed you'll see the following generated file: `kubernetes/kafka-client-keystore.yaml` containing the keystore.

## Image building for the gitops profile

### Image building using the Serverless Workflows Builder (recommended approach)

To build the image with the logic-swf-builder execute this command:

````
./scripts/build-image.sh 
````

> **NOTE:** Before executing you might need to adjust the `REGISTRY` and `REGISTRY_USER` see the script.
> 
> After building and publishing the image, make sure that you change the SonataFlow CR `spec.podTemplate.container.image` 
> field accordingly, see: [kubernetes/02-sonataflow_helloworld.yaml](kubernetes/02-sonataflow_helloworld.yaml).  


### Image building using the standalone Dockerfile.jvm 

To build the image using the standalone Dockerfile.jvm created by Quarkus you must execute these commands:

````
mvn clean install -DskipTests
````

````
./scripts/build-image-jvm.sh
````

> **NOTE:** Before executing you might need to adjust the `REGISTRY` and `REGISTRY_USER` see the script.
>
> After building and publishing the image, make sure that you change the SonataFlow CR `spec.podTemplate.container.image`
> field accordingly, see: [kubernetes/02-sonataflow_helloworld.yaml](kubernetes/02-sonataflow_helloworld.yaml).


## Example installation

To install the example execute these commands:

1. Create the namespace 
````
oc create namespace sonataflow-kafka-example
````

2. Deploy the SonataFlowPlatform and give it some for the Data Index and Jobs Service to start

````
oc apply -f kubernetes/00-sonataflow_platform.yaml -n sonataflow-kafka-example
````

You can verify that the pods are ready with the following command:

````
oc get pods -n sonataflow-kafka-example
````

3. Deploy the workflow truststore and keystore 

````
oc apply -f kubernetes/kafka-client-truststore.yaml -n sonataflow-kafka-example
````

````
oc apply -f kubernetes/kafka-client-keystore.yaml -n sonataflow-kafka-example
````

4. Deploy the workflow properties and the workflow in this order

````
oc apply -f kubernetes/01-configmap_helloworld-props.yaml -n sonataflow-kafka-example
````
````
oc apply -f kubernetes/02-sonataflow_helloworld.yaml -n sonataflow-kafka-example
````


You can monitor the workflow deployment with this command:

````
oc get workflows -n sonataflow-kafka-example
````

Note: it might take some time for the WF to start.
When ready, you'll see an output like this:

````
NAME         PROFILE   VERSION   URL   READY   REASON
helloworld   gitops    1.0             True 
````


## Workflow execution

To execute and verify the workflow we recommend that you use these utilities:

1. Start the `workflow-exit-event-consumer`

This script starts a simple kafka consumer that lets you monitor the `exit_event` produced by the workflow upon finalization.

Execute it in a separate terminal.

````
./scripts/workflow-exit-event-consumer.sh 
````

2. Start the `workflow-start-event-consumer` (optional)

This script starts a simple kafka consumer that lets you monitor the `start_event`s that the workflow is receiving,
and can be useful in scenarios where the events for the workflow are produced by an external entity.

Execute it in a separate terminal.

````
./scripts/workflow-start-event-consumer.sh 
````

3. Execute the workflow

To produce the start events for the workflow you can use the [scripts/workflow-start-event-producer.sh](scripts/workflow-start-event-producer.sh) script.

Execute it in a separate terminal.

````
./scripts/workflow-start-event-producer.sh 
````

After executing the script you'll see an output like this:

````
If you don't see a command prompt, try pressing enter.
pod "start-event-producer" deleted
````

And, in the workflow-exit-event-consumer terminal, you'll find the event produced by the workflow when finishing.
For every new workflow instance, you should see the corresponding exit_event.

````
$ ./scripts/workflow-exit-event-consumer.sh

Warning: would violate PodSecurity "restricted:latest": allowPrivilegeEscalation != false (container "workflow-exit-event-consumer" must set securityContext.allowPrivilegeEscalation=false), unrestricted capabilities (container "workflow-exit-event-consumer" must set securityContext.capabilities.drop=["ALL"]), runAsNonRoot != true (pod or container "workflow-exit-event-consumer" must set securityContext.runAsNonRoot=true), seccompProfile (pod or container "workflow-exit-event-consumer" must set securityContext.seccompProfile.type to "RuntimeDefault" or "Localhost")
If you don't see a command prompt, try pressing enter. 

{"specversion":"1.0","id":"2ba70118-251d-4906-a018-c4d2b12dba11","source":"/process/helloworld","type":"exit_event","time":"2025-08-13T10:41:39.143099686Z","kogitoproctype":"SW","kogitoprocinstanceid":"c6324b2b-5e3c-46e5-afca-4531bdfe1e20","kogitoprocist":"Active","kogitoprocversion":"1.0","kogitoprocid":"helloworld","data":{"message":"Start Hello World CloudEvent!","greeting":"Hello World","mantra":"Serverless Workflow is awesome!"}}
````

4. Data Index queries (optional)

In the Pod corresponding to the Data Index, you can execute the following queries to verify the proper registration
of the workflow and the subsequent executions.

````
curl -H "Content-Type: application/json" -H "Accept: application/json" -X POST --data '{"query" : "{ ProcessDefinitions { id, metadata } }"  }' http://sonataflow-platform-data-index-service/graphql
````

````
curl -H "Content-Type: application/json" -H "Accept: application/json" -X POST --data '{"query" : "{ ProcessInstances { id, processId, state, endpoint, serviceUrl, start, end } }"  }' http://sonataflow-platform-data-index-service/graphql
````
