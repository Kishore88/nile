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
locals {
  broker_allowed_sgs = compact(
    concat([aws_security_group.base_sg.id], var.broker_allowed_sgs),
  )

  broker_conf_key      = "kafka/server.properties"
  broker_conf_path     = "/etc/kafka/server.properties"
  broker_mount_point   = "/var/lib/kafka"
  broker_resource_tag  = "uuid"
  broker_routing_table = "kafka"
  broker_service_name  = "kafka"
  broker_service_user  = "kafka"

  host_names = [for i in range(var.broker_count) :
  replace(aws_route53_record.broker_route53_records[i].fqdn, "/[.]$/", "")]

  broker_private_ips = [
    aws_network_interface.broker_eni.*.private_ip,
  ]

  broker_uuid = [for i in range(var.broker_count) :
    {
      uuid  = random_uuid.broker_uuid[i].result
      Name  = "${local.broker_resource_prefix}${i}"
    }]

  broker_asg_tags = [for key in keys(var.deployment_tags) :
    {
      key                 = key
      value               = var.deployment_tags[key]
      propagate_at_launch = true
    }]
}

resource "random_string" "broker_store_password" {
  count   = var.broker_count
  special = false
  length  = 16
}

data "template_file" "broker_user_data" {
  count = var.broker_count

  template = file("${path.module}/templates/kafka-user-data.tpl")

  vars = {
    AWS_REGION      = var.deployment_region
    DEPLOY_UUID     = local.broker_uuid[count.index]["uuid"]
    MYID            = count.index
    NIC_IP          = aws_network_interface.broker_eni[count.index].private_ip
    SERVICE_NAME    = local.broker_service_name
    TAG_KEY         = local.broker_resource_tag
    ZOOKEEPER_IPS   = join(",", formatlist("%s:2181", aws_network_interface.zk_eni.*.private_ip))
    ELS_HOSTNAME    = local.els_hostname
    S3_CERTS_BUCKET = local.s3_certs_name
    HOST_NAME       = local.host_names[count.index]

    SECURITY_SCRAM_DYNAMODB_TABLE_NAME = aws_dynamodb_table.scram_store.id
    DEPLOYMENT_REGION                  = var.deployment_region
    SECURITY_SCRAM_CALLBACK_HANDLER    = var.security_scram_handler

    // Kafka config
    KFKCFG_SUPER_USERS = join(";", concat(module.certificate.broker_subjects, var.security_additional_super_users_subjects,
      // SCRAM: subjects are just app_names
      formatlist("User:app-%s", local.all_apps),
      // Terraform ops admin
    ["User:${var.terraform_kafka_user}"]))

    KFKCFG_SSL_KEYSTORE_PASSWORD          = random_string.broker_store_password[count.index].result
    KFKCFG_SSL_KEY_PASSWORD               = random_string.broker_store_password[count.index].result
    KFKCFG_LISTENERS                      = var.security_broker_client_allow_anyone == true ? "PLAINTEXT://${local.host_names[count.index]}:${var.broker_pt_port},SSL://${local.host_names[count.index]}:${var.broker_ssl_port},SASL_SSL://${local.host_names[count.index]}:${var.broker_sasl_port}" : "SSL://${local.host_names[count.index]}:${var.broker_ssl_port},SASL_SSL://${local.host_names[count.index]}:${var.broker_sasl_port}"
    KFKCFG_ADVERTISED_LISTENERS           = var.security_broker_client_allow_anyone == true ? "PLAINTEXT://${local.host_names[count.index]}:${var.broker_pt_port},SSL://${local.host_names[count.index]}:${var.broker_ssl_port},SASL_SSL://${local.host_names[count.index]}:${var.broker_sasl_port}" : "SSL://${local.host_names[count.index]}:${var.broker_ssl_port},SASL_SSL://${local.host_names[count.index]}:${var.broker_sasl_port}"
    KFKCFG_SECURITY_INTER_BROKER_PROTOCOL = var.security_interbroker_security_enabled == true ? "SSL" : "PLAINTEXT"
    KFKCFG_SSL_CLIENT_AUTH                = var.security_broker_client_allow_anyone == true ? "requested" : "required"
    KFKCFG_S3_CERTS_BUCKET                = local.s3_certs_name
    KFKCFG_MESSAGE_MAX_BYTES              = var.broker_message_max_bytes
    KFKCFG_MIN_INSYNC_REPLICAS            = 2
    KFKCFG_QUOTA_PRODUCER_DEFAULT         = 20971520 // 20 Mega bytes per sec
    KFKCFG_QUOTA_CONSUMER_DEFAULT         = 20971520 // 20 Mega bytes per sec
    KFKCFG_COMPRESSION_TYPE               = "snappy"
    KFKCFG_AUTO_CREATE_TOPICS_ENABLE      = "false"
    KFKCFG_AUTHORIZER_CLASS_NAME          = var.security_broker_client_allow_anyone == false && var.security_interbroker_security_enabled == true ? "kafka.security.auth.SimpleAclAuthorizer" : ""
    KFKCFG_AUTO_CREATE_TOPICS_ENABLE      = "false"
    KFKCFG_ZOOKEEPER_SASL_ENABLED         = "false"
    KFKCFG_DELETE_TOPIC_ENABLE            = var.topics_allow_deletion == true ? "true" : "false"
    KFKCFG_INTER_BROKER_PROTOCOL_VERSION  = var.broker_inter_broker_protocol_version
    KFKCFG_SASL_ENABLED_MECHANISMS        = join(",", var.security_scram_mechanisms)
    SCRAM_CALLBACK_HANDLER                = var.security_scram_handler

  }
}

data "aws_subnet" "broker_subnet" {
  count = var.broker_count

  id = element(var.subnet_ids, count.index)
}

resource "random_uuid" "broker_uuid" {
  count = var.broker_count
}

resource "aws_network_interface" "broker_eni" {
  count = var.broker_count

  subnet_id = var.subnet_ids[count.index]

  security_groups = [
    aws_security_group.broker_sg.id,
    aws_security_group.monitoring_sg.id
  ]

  tags = merge(
    var.deployment_tags,
    local.broker_uuid[count.index],
  )
}

data "aws_route53_zone" "env_zone" {
  name = var.dns_zone
}

resource "aws_route53_zone" "cluster_brokers_zone" {
  name = "${var.deployment_name}.${data.aws_route53_zone.env_zone.name}"
}

resource "aws_route53_record" "cluster_brokers_zone_records" {
  zone_id = data.aws_route53_zone.env_zone.zone_id
  name    = aws_route53_zone.cluster_brokers_zone.name
  type    = "NS"
  ttl     = "30"

  records = aws_route53_zone.cluster_brokers_zone.name_servers
}

resource "aws_route53_record" "broker_route53_records" {
  count   = var.broker_count
  zone_id = aws_route53_zone.cluster_brokers_zone.zone_id
  name    = "broker-${count.index}"
  type    = "A"
  ttl     = "60"
  records = [aws_network_interface.broker_eni[count.index].private_ip]
}

resource "aws_ebs_volume" "broker_ebs" {
  count = var.broker_count

  availability_zone = element(
    data.aws_subnet.broker_subnet.*.availability_zone,
    count.index,
  )
  size      = var.broker_volume_size
  type      = "gp2"
  encrypted = "true"

  tags = merge(
    var.deployment_tags,
    local.broker_uuid[count.index],
  )
}

resource "aws_security_group" "broker_sg" {
  name        = local.broker_sg_name
  description = "Kafka Broker traffic allowance"
  vpc_id      = var.vpc_id

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }
}

resource "aws_security_group_rule" "broker_allow_ingress_cluster" {
  security_group_id = aws_security_group.broker_sg.id

  type                     = "ingress"
  from_port                = 9092
  to_port                  = 9092
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.broker_sg.id
}

resource "aws_security_group_rule" "broker_allow_ingress_cluster_ssl" {
  security_group_id = aws_security_group.broker_sg.id

  type                     = "ingress"
  from_port                = var.broker_ssl_port
  to_port                  = var.broker_ssl_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.broker_sg.id
}

resource "aws_security_group_rule" "broker_allow_ingress_external" {
  security_group_id = aws_security_group.broker_sg.id

  type        = "ingress"
  from_port   = 9092
  to_port     = 9092
  protocol    = "tcp"
  cidr_blocks = var.broker_sg_cidr_allowed
}

resource "aws_security_group_rule" "broker_allow_ingress_external_ssl" {
  security_group_id = aws_security_group.broker_sg.id

  type        = "ingress"
  from_port   = var.broker_ssl_port
  to_port     = var.broker_ssl_port
  protocol    = "tcp"
  cidr_blocks = var.broker_sg_cidr_allowed
}

resource "aws_security_group_rule" "broker_allow_ingress_external_sasl" {
  security_group_id = aws_security_group.broker_sg.id

  type        = "ingress"
  from_port   = var.broker_sasl_port
  to_port     = var.broker_sasl_port
  protocol    = "tcp"
  cidr_blocks = var.broker_sg_cidr_allowed
}

resource "aws_launch_configuration" "broker_lc" {
  count = var.broker_count

  name_prefix   = "${local.broker_lc_name_prefix}${count.index}-"
  image_id      = local.broker_ami_id
  instance_type = var.broker_instance_type

  user_data = element(data.template_file.broker_user_data.*.rendered, count.index)

  key_name             = var.deployment_ssh_key
  iam_instance_profile = aws_iam_instance_profile.instance_profile.name


  security_groups = local.broker_allowed_sgs

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "broker_asg" {
  count = var.broker_count

  name_prefix          = "${local.broker_asg_name_prefix}${count.index}-"
  launch_configuration = element(aws_launch_configuration.broker_lc.*.name, count.index)

  vpc_zone_identifier = [element(var.subnet_ids, count.index)]

  default_cooldown          = 0
  health_check_grace_period = 30

  desired_capacity = 1
  max_size         = 1
  min_size         = 1

  tags = concat(local.broker_asg_tags,
    [
      {
        key                 = "Name"
        value               = "${local.broker_resource_prefix}${count.index}"
        propagate_at_launch = true
      },
      {
        key                 = "uuid"
        value               = element(random_uuid.broker_uuid.*.result, count.index)
        propagate_at_launch = true
      },
      {
        key                 = "deployment-name"
        value               = var.deployment_name
        propagate_at_launch = true
      },
  ])

}


################################################################################
##                                                                            ##
##                   ----==| S C R A M   S T O R E |==----                    ##
##                                                                            ##
################################################################################

resource "aws_dynamodb_table" "scram_store" {
  name         = "${var.security_scram_dynamodb_table_name_prefix}${var.deployment_name}-scram-store"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "username"

  attribute {
    name = "username"
    type = "S"
  }
  tags = var.deployment_tags
}
