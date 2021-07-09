# Default values for cp-kafka-connect.
# This is a YAML-formatted file.
# Declare variables to be passed into your templates.

replicaCount: ${KC_KFK_REPLICA_COUNT}

## Image Info
## ref: https://hub.docker.com/r/confluentinc/cp-kafka/
image: ${KC_IMAGE_URL}
imageTag: ${KC_IMAGE_TAG}

## Specify a imagePullPolicy
## ref: http://kubernetes.io/docs/user-guide/images/#pre-pulling-images
imagePullPolicy: IfNotPresent

## Specify an array of imagePullSecrets.
## Secrets must be manually created in the namespace.
## ref: https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod
imagePullSecrets:

servicePort: 8083

## Kafka Connect properties
## ref: https://docs.confluent.io/current/connect/userguide.html#configuring-workers
configurationOverrides:
  "plugin.path": "/usr/share/java,/usr/share/confluent-hub-components"
  "key.converter": "io.confluent.connect.avro.AvroConverter"
  "value.converter": "io.confluent.connect.avro.AvroConverter"
  "key.converter.schemas.enable": "false"
  "value.converter.schemas.enable": "false"
  "internal.key.converter": "org.apache.kafka.connect.json.JsonConverter"
  "internal.value.converter": "org.apache.kafka.connect.json.JsonConverter"
  "config.storage.replication.factor": "3"
  "offset.storage.replication.factor": "3"
  "status.storage.replication.factor": "3"
  "security.protocol": "${KC_KFK_SECURITY_PROTOCOL}"
  "producer.security.protocol": "${KC_KFK_SECURITY_PROTOCOL}"
  "consumer.security.protocol": "${KC_KFK_SECURITY_PROTOCOL}"
  "producer.bootstrap.servers": "${KC_KFK_BOOTSTRAP_SERVERS}"
  "consumer.bootstrap.servers": "${KC_KFK_BOOTSTRAP_SERVERS}"
  "connector.client.config.override.policy": "All"
  "sasl.mechanism": "SCRAM-SHA-512"
  "consumer.sasl.mechanism": "SCRAM-SHA-512"
  "producer.sasl.mechanism": "SCRAM-SHA-512"
  "session.timeout.ms": "${KC_SESSION_TIMEOUT}"
  "consumer.session.timeout.ms": "${KC_SESSION_TIMEOUT}"
  "heartbeat.interval.ms": "${KC_HEARTBEAT_INTERVAL}"
  "consumer.heartbeat.interval.ms": "${KC_HEARTBEAT_INTERVAL}"

## Kafka Connect JVM Heap Option
heapOptions: "-XX:InitialRAMPercentage=50 -XX:MaxRAMPercentage=90"

## Additional env variables
customEnv:
  KAFKA_JVM_PERFORMANCE_OPTS: "-server -XX:+UseG1GC -XX:MaxGCPauseMillis=2000 -XX:+ExplicitGCInvokesConcurrent -XX:+ExitOnOutOfMemoryError -Djava.awt.headless=true"

resources:
  # We usually recommend not to specify default resources and to leave this as a conscious
  # choice for the user. This also increases chances charts run on environments with little
  # resources, such as Minikube. If you do want to specify resources, uncomment the following
  # lines, adjust them as necessary, and remove the curly braces after 'resources:'.
  limits:
    cpu: ${KC_KFK_CPU_LIMIT}
    memory: ${KC_KFK_MEM_LIMIT}
  requests:
    cpu: ${KC_KFK_CPU_REQ}
    memory: ${KC_KFK_MEM_REQ}

## Custom pod annotations
podAnnotations: {}

## Node labels for pod assignment
## Ref: https://kubernetes.io/docs/concepts/configuration/assign-pod-node/
nodeSelector: {}

## Taints to tolerate on node assignment:
## Ref: https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/
tolerations: {}

## Monitoring
## Kafka Connect JMX Settings
## ref: https://kafka.apache.org/documentation/#connect_monitoring
jmx:
  port: 5555

## Prometheus Exporter Configuration
## ref: https://prometheus.io/docs/instrumenting/exporters/
prometheus:
  ## JMX Exporter Configuration
  ## ref: https://github.com/prometheus/jmx_exporter
  jmx:
    enabled: ${KC_JMX_EXPORTER}
    image: solsson/kafka-prometheus-jmx-exporter@sha256
    imageTag: 6f82e2b0464f50da8104acd7363fb9b995001ddff77d248379f8788e78946143
    imagePullPolicy: IfNotPresent
    port: 5556

    ## Resources configuration for the JMX exporter container.
    ## See the `resources` documentation above for details.
    resources: {}

## You can list load balanced service endpoint, or list of all brokers (which is hard in K8s).  e.g.:
## bootstrapServers: "PLAINTEXT://dozing-prawn-kafka-headless:9092"
kafka:
  bootstrapServers: "${KC_KFK_BOOTSTRAP_SERVERS}"

## If the Kafka Chart is disabled a URL and port are required to connect
## e.g. gnoble-panther-cp-schema-registry:8081
cp-schema-registry:
  url: "${KC_SCHEMA_REGISTRY_URL}"

secrets:
 - name: connect
   keys:
     - sasl_jaas_config
     - consumer_sasl_jaas_config
     - producer_sasl_jaas_config

# health check
healthcheck:
  enabled:  ${KC_IMAGE_HEALTHCHECK_ENABLED}
  image: "${KC_IMAGE_HEALTHCHECK_URL}"
  tag: ${KC_IMAGE_HEALTHCHECK_TAG}
  connectEndpoint: http://localhost:8083
  pgEndpoint: ${PUSHGATEWAY_ENDPOINT}
  env: "${ENV}"

livenessProbe:
  httpGet:
    path: /health-check
    port: 9090
  initialDelaySeconds: 90
  timeoutSeconds: ${KC_HEALTHCHECK_TIMEOUT}
  failureThreshold: ${KC_HEALTHCHECK_FAILURE_THRESHOLD}
  successThreshold: ${KC_HEALTHCHECK_SUCCESS_THRESHOLD}
  periodSeconds: ${KC_HEALTHCHECK_INTERVAL}

