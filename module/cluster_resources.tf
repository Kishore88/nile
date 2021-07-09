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

################################################################################
##                                                                            ##
##            ----==| U S E R   &   T O P I C S   A C L S |==----             ##
##                                                                            ##
################################################################################

locals {
  bootstrap_servers = [for fqdn in aws_route53_record.broker_route53_records.*.fqdn :
  "${fqdn}:${var.broker_sasl_port}"]

  topics_map = zipmap(var.topics.*.name, var.topics.*)

  write_acls = flatten([for user in var.users_acls :
    [for acl in user.write_access :
      {
        name            = "${user.name}_${acl.topic_prefix}"
        resource_prefix = acl.topic_prefix
        username        = user.name
  }]])

  delete_acls = flatten([for user in var.users_acls :
    [for acl in user.delete_access :
      {
        name            = "${user.name}_${acl.topic_prefix}"
        resource_prefix = acl.topic_prefix
        username        = user.name
  }]])

  default_acls = [
    {
      name = "default_acls_read_all_topics"
      resource_type = "Topic"
      resource_name = "*"
      operation = "Read"
    },
    // needed to fetch partition metadata
    {
      name = "default_acls_cluster_actions"
      resource_type = "Cluster"
      resource_name = "kafka-cluster"
      operation = "ClusterAction"
    },
    {
      name = "default_acls_cluster_describe"
      resource_type = "Cluster"
      resource_name = "kafka-cluster"
      operation = "Describe"
    },
    {
      name = "default_acls_read_all_groups"
      resource_type = "Group"
      resource_name = "*"
      operation = "Read"
    },
    {
      name = "default_acls_write_consumer_offset"
      resource_name = "__consumer_offsets"
      resource_type = "Topic"
      operation = "Write"
    }
  ]

  write_acls_map = zipmap(local.write_acls.*.name, local.write_acls.*)
  delete_acls_map = zipmap(local.delete_acls.*.name, local.delete_acls.*)
  default_acls_map = zipmap(local.default_acls.*.name, local.default_acls.*)
}

provider "kafka" {
  bootstrap_servers = local.bootstrap_servers

  tls_enabled    = true
  sasl_username  = var.terraform_kafka_user
  sasl_password  = var.terraform_kafka_user_password
  sasl_mechanism = var.terraform_kafka_mechanism
}


resource "kafka_topic" "topics" {
  for_each           = tomap(local.topics_map)
  name               = each.value.name
  replication_factor = each.value.replication_factor
  partitions         = each.value.partitions
  config             = each.value.config
}

resource "kafka_acl" "default_acls" {
  for_each            = tomap(local.default_acls_map)
  resource_name       = each.value.resource_name
  resource_type       = each.value.resource_type
  acl_principal       = "User:*"
  acl_host            = "*"
  acl_operation       = each.value.operation
  acl_permission_type = "Allow"
}

resource "kafka_acl" "users_write_acls" {
  for_each                     = tomap(local.write_acls_map)
  resource_name                = each.value.resource_prefix
  resource_pattern_type_filter = "Prefixed"
  resource_type                = "Topic"
  acl_principal                = "User:${each.value.username}"
  acl_host                     = "*"
  acl_operation                = "Write"
  acl_permission_type          = "Allow"
}

resource "kafka_acl" "users_delete_acls" {
  for_each                     = tomap(local.delete_acls_map)
  resource_name                = each.value.resource_prefix
  resource_pattern_type_filter = "Prefixed"
  resource_type                = "Topic"
  acl_principal                = "User:${each.value.username}"
  acl_host                     = "*"
  acl_operation                = "Delete"
  acl_permission_type          = "Allow"
}

resource "kafka_acl" "users_idempotent_write_acls" {
  for_each                     = tomap(local.write_acls_map)
  resource_name                = "kafka-cluster"
  resource_type                = "Cluster"
  acl_principal                = "User:${each.value.username}"
  acl_host                     = "*"
  acl_operation                = "IdempotentWrite"
  acl_permission_type          = "Allow"
}

resource "kafka_acl" "users_tx_write_acls" {
  for_each                     = tomap(local.write_acls_map)
  resource_name                = "*"
  resource_type                = "TransactionalID"
  acl_principal                = "User:${each.value.username}"
  acl_host                     = "*"
  acl_operation                = "Write"
  acl_permission_type          = "Allow"
}
