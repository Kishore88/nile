# Default values for kafka-watchdog.
# This is a YAML-formatted file.
# Declare variables to be passed into your templates.

image:
  repository:  ${KW_IMAGE_URL}
  tag: ${KW_IMAGE_TAG}
  pullPolicy: IfNotPresent

service:
  name: kafka-watchdog
  type: ClusterIP
  externalPort: 8080
  internalPort: 8080

ingress:
  enabled: false

nodeSelector: {}

tolerations: []

affinity: {}

env_vars:
  ENV: ${KW_CFG_ENV}

resources:
  limits:
    cpu: ${KW_KFK_CPU_LIMIT}
    memory: ${KW_KFK_MEM_LIMIT}
  requests:
    cpu: ${KW_KFK_CPU_REQ}
    memory: ${KW_KFK_MEM_REQ}

livenessProbe:
  httpGet:
    path: /health-check
    port: 8080
  initialDelaySeconds: 60
  periodSeconds: 60
  timeoutSeconds: 30
  successThreshold: 1
  failureThreshold: 3
