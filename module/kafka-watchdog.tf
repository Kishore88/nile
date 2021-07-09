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

variable "kafka_watchdog_app_name" {
  type    = string
  default = "kafka-watchdog"
}

data "template_file" "kw_values" {
  count    = var.kafka_watchdog_enabled == true ? 1 : 0
  template = file("${path.module}/templates/kw-helm-values.yaml.tpl")
  vars = {
    KW_IMAGE_URL = var.kafka_watchdog_image_url
    KW_IMAGE_TAG = var.kafka_watchdog_image_tag
    KW_CFG_ENV   = var.kafka_watchdog_cfg_env
    KW_KFK_CPU_REQ = var.kafka_watchdog_container_cpu_req
    KW_KFK_MEM_REQ = var.kafka_watchdog_container_mem_req
    KW_KFK_CPU_LIMIT = var.kafka_watchdog_container_cpu_limit
    KW_KFK_MEM_LIMIT = var.kafka_watchdog_container_mem_limit
  }
}

data "template_file" "kw_policy" {
  count    = var.kafka_watchdog_enabled == true ? 1 : 0
  template = file("${path.module}/templates/kafka-watchdog-policy.json.tpl")
  vars = {
    KW_CONFIG_KEY = var.kafka_watchdog_config_key
  }
}

resource "helm_release" "kafka-watchdog" {
  count     = var.kafka_watchdog_enabled == true ? 1 : 0
  name      = var.kafka_watchdog_app_name
  chart     = "${path.module}/charts/kafka-watchdog"
  version   = "0.1.5"
  namespace = var.sr_eks_namespace
  values = [
    data.template_file.kw_values[0].rendered
  ]
  wait = "false"

  depends_on = [
    data.template_file.kw_values
  ]
}

resource "aws_iam_policy" "kafka_watchdog_policy" {
  count  = var.kafka_watchdog_enabled == true ? 1 : 0
  name   = "kafka-watchdog-1config-${var.kafka_watchdog_cfg_env}-policy"
  policy = data.template_file.kw_policy[0].rendered
}

data "aws_iam_role" "eks_role_ec2" {
  count = var.kafka_watchdog_enabled == true ? 1 : 0
  name  = var.kafka_watchdog_eks_role_name
}

resource "aws_iam_role_policy_attachment" "kafka-watchdog-policy-attach" {
  count      = var.kafka_watchdog_enabled == true ? 1 : 0
  role       = data.aws_iam_role.eks_role_ec2[0].name
  policy_arn = aws_iam_policy.kafka_watchdog_policy[0].arn
}
