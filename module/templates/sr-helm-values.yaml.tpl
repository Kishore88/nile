replicaCount: ${SR_KFK_REPLICA_COUNT}

image: ${SR_KFK_IMAGE}
imageTag: ${SR_KFK_TAG}

kafkaStore:
  overrideBootstrapServers: "${SR_KFK_BOOTSTRAP_SERVERS}"

kafka:
  enabled: false

configurationOverrides:
  kafkastore.security.protocol: ${SR_KFK_SECURITY_PROTOCOL}
  kafkastore.sasl.mechanism: SCRAM-SHA-512
  avro.compatibility.level: "forward_transitive"
  heap.opts: "-Xms250M -Xmx800M"
  jvm.performance.opts: "-server -XX:+UseG1GC -XX:MaxGCPauseMillis=800 -XX:+ExplicitGCInvokesConcurrent -XX:+ExitOnOutOfMemoryError -Djava.awt.headless=true"

ingress:
  enabled: false

resources:
  limits:
    cpu: ${SR_KFK_CPU_LIMIT}
    memory: ${SR_KFK_MEM_LIMIT}
  requests:
    cpu: ${SR_KFK_CPU_REQ}
    memory: ${SR_KFK_MEM_REQ}


secrets:
 - name: schema-registry-kafkastore
   keys:
     - sasl_jaas_config

prometheus:
  jmx:
    enabled: true
    port: ${SR_PROMETHEUS_JMX_PORT}

readinessProbe:
  initialDelaySeconds: 60
  periodSeconds: ${SR_KFK_HEALTH_CHECK_SUCCESS}
  timeoutSeconds: 30
  successThreshold: 1
  failureThreshold: 3

livenessProbe:
  initialDelaySeconds: 60
  periodSeconds: ${SR_KFK_HEALTH_CHECK_SUCCESS}
  timeoutSeconds: 30
  successThreshold: 1
  failureThreshold: 3
