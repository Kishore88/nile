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
provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.sr_eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.sr_eks.certificate_authority.0.data)
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.sr_eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.sr_eks.certificate_authority.0.data)
}

data "aws_eks_cluster" "sr_eks" {
  name = var.schema_registry_eks_name
}

data "helm_repository" "incubator" {
  name = "incubator"
  url  = "https://charts.helm.sh/incubator"
}

resource "null_resource" "create_sr_scram_secret" {
  count    = var.schema_registry_enabled == true ? 1 : 0
  triggers = {
    fexec = sha256(filebase64("${path.module}/resource/gen_k8s_secret.sh"))
  }

  provisioner "local-exec" {
    command = "${path.module}/resource/gen_k8s_secret.sh"

    environment = {
      SECRET_NAME         = "schema-registry-kafkastore"
      SECRET_NAMESPACE    = var.sr_eks_namespace
      SECRET_KEY_VALUE    = format("org.apache.kafka.common.security.scram.ScramLoginModule required username=\"app-schema-registry\" password=\"%s\";", var.schema_registry_app_scram_password)
      SASL_CONNECT_EXTRAS = -1
    }
  }
}

data "template_file" "sr_values" {
  template = file("${path.module}/templates/sr-helm-values.yaml.tpl")

  vars = {
    SR_KFK_BOOTSTRAP_SERVERS = var.security_broker_client_allow_anyone == false ? join(",", formatlist("SASL_SSL://%s:${var.broker_sasl_port}", local.host_names)) : join(",", formatlist("PLAINTEXT://%s:${var.broker_pt_port}", local.host_names))
    SR_KFK_SECURITY_PROTOCOL = var.security_broker_client_allow_anyone == false ? "SASL_SSL" : "PLAINTEXT"
    SR_PROMETHEUS_JMX_PORT   = 5556
    SR_KFK_REPLICA_COUNT     = var.schema_registry_replica_count
    SR_KFK_CPU_LIMIT         = var.schema_registry_container_cpu_limit
    SR_KFK_MEM_LIMIT         = var.schema_registry_container_mem_limit
    SR_KFK_IMAGE             = var.schema_registry_image
    SR_KFK_TAG               = var.schema_registry_tag
    SR_KFK_CPU_REQ           = var.schema_registry_container_cpu_req
    SR_KFK_MEM_REQ           = var.schema_registry_container_mem_req
    SR_KFK_HEALTH_CHECK_SUCCESS = var.schema_registry_healthcheck_interval
  }

}

resource "helm_release" "kafka-schema-registry" {
  count      = var.schema_registry_enabled == true ? 1 : 0
  name       = "kafka-schema-registry"
  repository = data.helm_repository.incubator.metadata[0].name
  chart      = "incubator/schema-registry"
  version    = "1.2.0"
  namespace  = var.sr_eks_namespace
  values = [
    data.template_file.sr_values.rendered
  ]
  wait = "false"
  depends_on = [
    null_resource.create_sr_scram_secret,
    data.template_file.sr_values
  ]

}

resource "kubernetes_ingress" "kafka-schema-registry-ingress" {
  count   = var.schema_registry_enabled == true ? 1 : 0
  metadata {
    name      = "kafka-schema-registry"
    namespace = var.sr_eks_namespace
    labels = {
      app = "kafka-schema-registry"
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
      host = "${var.schema_registry_app_name}.${local.cn_suffix}"
      http {
        path {
          backend {
            service_name = "kafka-schema-registry"
            service_port = 8081
          }
          path = "/*"
        }
      }
    }
  }
  depends_on = [
    helm_release.kafka-schema-registry,
    aws_acm_certificate.cert_https_sr
  ]
}

resource "aws_route53_record" "sr_dns_record" {
  count   = var.schema_registry_enabled == true ? 1 : 0
  zone_id = aws_route53_zone.cluster_brokers_zone.zone_id
  name    = "${var.schema_registry_app_name}.${local.cn_suffix}"
  type    = "A"

  alias {
    name                   = kubernetes_ingress.kafka-schema-registry-ingress[0].status[0].load_balancer[0].ingress[0].hostname
    zone_id                = var.eks_lb_zone_id
    evaluate_target_health = true
  }

  depends_on = [
    kubernetes_ingress.kafka-schema-registry-ingress
  ]

}
