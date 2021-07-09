#
# Copyright 2020-2021 VIOOH Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#  local helm repo
//data "helm_repository" "data_helm" {
//    name = "data_helm"
//    url  = "http://127.0.0.1:8879/"
//}

variable "kafka_connect_app_name" {
  type    = string
  default = "kafka-connect"
}

resource "null_resource" "create_kc_scram_secret" {
  count = var.kafka_connect_enabled == true ? 1 : 0
  triggers = {
    fexec = sha256(filebase64("${path.module}/resource/gen_k8s_secret.sh"))
  }

  provisioner "local-exec" {
    command = "${path.module}/resource/gen_k8s_secret.sh"

    environment = {
      SECRET_NAME         = "connect"
      SECRET_NAMESPACE    = var.sr_eks_namespace
      SECRET_KEY_VALUE    = format("org.apache.kafka.common.security.scram.ScramLoginModule required username=\"app-kafka-connect\" password=\"%s\";", var.kafka_connect_app_scram_password)
      SASL_CONNECT_EXTRAS = 1
    }
  }
}

data "template_file" "kc_values" {
  template = file("${path.module}/templates/kc-helm-values.yaml.tpl")

  vars = {
    KC_KFK_BOOTSTRAP_SERVERS     = var.security_broker_client_allow_anyone == false ? join(",", formatlist("SASL_SSL://%s:${var.broker_sasl_port}", local.host_names)) : join(",", formatlist("PLAINTEXT://%s:${var.broker_pt_port}", local.host_names))
    KC_KFK_SECURITY_PROTOCOL     = var.security_broker_client_allow_anyone == false ? "SASL_SSL" : "PLAINTEXT"
    KC_SCHEMA_REGISTRY_URL       = "http://kafka-schema-registry:8081"
    KC_IMAGE_URL                 = var.kafka_connect_image_url
    KC_IMAGE_TAG                 = var.kafka_connect_image_tag
    KC_KFK_REPLICA_COUNT         = var.kafka_connect_replica_count
    KC_KFK_MEM_LIMIT             = var.kafka_connect_container_mem_limit
    KC_KFK_CPU_LIMIT             = var.kafka_connect_container_cpu_limit
    KC_IMAGE_HEALTHCHECK_URL     = var.kafka_connect_healthcheck_image_url
    KC_IMAGE_HEALTHCHECK_TAG     = var.kafka_connect_healthcheck_image_tag
    KC_IMAGE_HEALTHCHECK_ENABLED = var.kafka_connect_healthcheck_enabled
    KC_JMX_EXPORTER              = var.kafka_connect_jmx_exporter
    KC_HEALTHCHECK_INTERVAL      = var.kafka_connect_healthcheck_interval
    KC_HEALTHCHECK_TIMEOUT       = var.kafka_connect_healthcheck_timeout
    KC_HEALTHCHECK_FAILURE_THRESHOLD = var.kafka_connect_healthcheck_failure_threshold
    KC_HEALTHCHECK_SUCCESS_THRESHOLD = var.kafka_connect_healthcheck_success_threshold
    KC_SESSION_TIMEOUT = var.kafka_connect_session_timeout
    KC_HEARTBEAT_INTERVAL = var.kafka_connect_hearbeat_interval
    KC_KFK_CPU_REQ = var.kafka_connect_container_cpu_req
    KC_KFK_MEM_REQ = var.kafka_connect_container_mem_req
    PUSHGATEWAY_ENDPOINT = var.kafka_connect_healthcheck_pg_endpoint
    ENV = var.env
  }

}

resource "helm_release" "kafka-connect" {
  count     = var.kafka_connect_enabled == true ? 1 : 0
  name      = "kafka-connect"
  chart     = "${path.module}/charts/kafka-connect"
  version   = "0.1.1"
  namespace = var.sr_eks_namespace
  values = [
    data.template_file.kc_values.rendered
  ]
  wait = "false"

  depends_on = [
    data.template_file.kc_values,
    null_resource.create_kc_scram_secret
  ]
}

resource "kubernetes_ingress" "kafka-connect-ingress" {
  count = var.kafka_connect_enabled == true ? 1 : 0
  metadata {
    name      = "kafka-connect"
    namespace = var.sr_eks_namespace
    labels = {
      app = "kafka-connect"
    }
    annotations = {
      "alb.ingress.kubernetes.io/certificate-arn" = aws_acm_certificate.cert_https_sr.arn
      "kubernetes.io/ingress.class"               = "alb"
      "alb.ingress.kubernetes.io/target-type"     = "ip"
      "alb.ingress.kubernetes.io/subnets"         = join(",", var.ingress_elb_subnet_ids)
    }
  }
  spec {
    rule {
      host = "${var.kafka_connect_app_name}.${local.cn_suffix}"
      http {
        path {
          backend {
            service_name = "kafka-connect"
            service_port = 8083
          }
          path = "/*"
        }
      }
    }
  }
  depends_on = [
    helm_release.kafka-connect,
    aws_acm_certificate.cert_https_sr
  ]
}

resource "aws_route53_record" "kc_dns_record" {
  count   = var.kafka_connect_enabled == true ? 1 : 0
  zone_id = aws_route53_zone.cluster_brokers_zone.zone_id
  name    = "${var.kafka_connect_app_name}.${local.cn_suffix}"
  type    = "A"

  alias {
    name                   = kubernetes_ingress.kafka-connect-ingress[0].status[0].load_balancer[0].ingress[0].hostname
    zone_id                = var.eks_lb_zone_id
    evaluate_target_health = true
  }

  depends_on = [
    kubernetes_ingress.kafka-connect-ingress
  ]
}
