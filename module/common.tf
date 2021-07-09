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
  broker_ami_id          = var.broker_ami_id == "" ? data.aws_ami.broker_ami[0].image_id : var.broker_ami_id
  broker_asg_name_prefix = "${var.deployment_name}-broker-"
  broker_lc_name_prefix  = "${var.deployment_name}-broker-"
  broker_resource_prefix = "${var.deployment_name}-broker-"
  broker_sg_name         = "${var.deployment_name}-broker"

  zk_ami_id          = var.zookeeper_ami_id == "" ? data.aws_ami.zk_ami[0].image_id : var.zookeeper_ami_id
  zk_asg_name_prefix = "${var.deployment_name}-zk-"
  zk_lc_name_prefix  = "${var.deployment_name}-zk-"
  zk_resource_prefix = "${var.deployment_name}-zk-"
  zk_sg_name         = "${var.deployment_name}-zk"
  base_sg_name       = var.deployment_name
  monitoring_sg_name = "${var.deployment_name}-monitoring"

  els_hostname = replace(var.els_endpoint, "https://", "")
}

data "aws_caller_identity" "current" {
}

data "aws_ami" "broker_ami" {
  count       = var.broker_ami_id == "" ? 1 : 0
  most_recent = true

  owners     = ["self"]
  name_regex = "${var.ami_kfk_prefix}nile-kafka-stretch-"
}

data "aws_ami" "zk_ami" {
  count       = var.zookeeper_ami_id == "" ? 1 : 0
  most_recent = true

  owners     = ["self"]
  name_regex = "${var.ami_zk_prefix}nile-zookeeper-stretch-"
}

resource "aws_security_group" "base_sg" {
  name        = local.base_sg_name
  description = "Base sg for kafka and zk"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.base_sg_cidr_allowed
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }
}

resource "aws_security_group" "monitoring_sg" {
  name        = local.monitoring_sg_name
  description = "Monitoring sg for kafka and zk"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "common_allow_ingress_prometheus_scrape_node_exporter" {
  count             = var.prometheus_sg_id == null ? 0 : 1
  security_group_id = aws_security_group.monitoring_sg.id

  type                     = "ingress"
  from_port                = 9100
  to_port                  = 9100
  protocol                 = "tcp"
  source_security_group_id = var.prometheus_sg_id
}

resource "aws_security_group_rule" "common_allow_ingress_prometheus_scrape_jmx_exporter" {
  count             = var.prometheus_sg_id == null ? 0 : 1
  security_group_id = aws_security_group.monitoring_sg.id

  type                     = "ingress"
  from_port                = 7070
  to_port                  = 7070
  protocol                 = "tcp"
  source_security_group_id = var.prometheus_sg_id
}
