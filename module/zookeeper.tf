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
  zk_allowed_sgs = compact(
    concat([aws_security_group.base_sg.id], var.zookeeper_allowed_sgs),
  )

  zk_conf_key      = "zk/zookeeper.properties"
  zk_conf_path     = "/etc/zookeeper/zookeeper.properties"
  zk_mount_point   = "/var/lib/zookeeper"
  zk_myid_key      = "zk"
  zk_myid_path     = "/var/lib/zookeeper/myid"
  zk_resource_tag  = "uuid"
  zk_routing_table = "zookeeper"
  zk_service_name  = "zookeeper"
  zk_service_user  = "zookeeper"

  zk_private_ips = [
    aws_network_interface.zk_eni.*.private_ip,
  ]

  zk_uuid = [for i in range(var.zookeeper_count) :
    {
      uuid  = random_uuid.zk_uuid[i].result
      Name  = "${local.zk_resource_prefix}${i}"
    }]

  zk_asg_tags = [for key in keys(var.deployment_tags) :
    {
      key                 = key
      value               = var.deployment_tags[key]
      propagate_at_launch = true
    }]

}

data "template_file" "zk_user_data" {
  count = var.zookeeper_count

  template = file("${path.module}/templates/zk-user-data.tpl")

  vars = {
    AWS_REGION    = var.deployment_region
    DEPLOY_UUID   = local.zk_uuid[count.index]["uuid"]
    MYID          = count.index + 1
    NIC_IP        = element(aws_network_interface.zk_eni.*.private_ip, count.index)
    SERVICE_NAME  = local.zk_service_name
    TAG_KEY       = local.zk_resource_tag
    ZOOKEEPER_IPS = "${join(":2181,", aws_network_interface.zk_eni.*.private_ip)}:2181"
    ELS_HOSTNAME  = local.els_hostname
  }
}

data "aws_subnet" "zk_subnet" {
  count = var.zookeeper_count

  id = element(var.subnet_ids, count.index)
}

resource "random_uuid" "zk_uuid" {
  count = var.zookeeper_count
}

resource "aws_network_interface" "zk_eni" {
  count = var.zookeeper_count

  subnet_id = element(var.subnet_ids, count.index)

  security_groups = [
    aws_security_group.zk_sg.id,
    aws_security_group.monitoring_sg.id
  ]

  tags = merge(
    var.deployment_tags,
    local.zk_uuid[count.index],
  )
}

resource "aws_ebs_volume" "zk_ebs" {
  count = var.zookeeper_count

  availability_zone = element(data.aws_subnet.zk_subnet.*.availability_zone, count.index)
  size              = var.zookeeper_volume_size
  type              = "gp2"
  encrypted         = true

  tags = merge(
    var.deployment_tags,
    local.zk_uuid[count.index],
  )
}

resource "aws_security_group" "zk_sg" {
  name        = local.zk_sg_name
  description = "Zookeeper traffic allowance"
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

resource "aws_security_group_rule" "zk_allow_kafka_broker_ingress" {
  security_group_id = aws_security_group.zk_sg.id

  type                     = "ingress"
  from_port                = 2181
  to_port                  = 2181
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.broker_sg.id
}

resource "aws_security_group_rule" "zk_allow_leader_election_ingress" {
  security_group_id = aws_security_group.zk_sg.id

  type                     = "ingress"
  from_port                = 3888
  to_port                  = 3888
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.zk_sg.id
}

resource "aws_security_group_rule" "zk_allow_follow_leader_ingress" {
  security_group_id = aws_security_group.zk_sg.id

  type                     = "ingress"
  from_port                = 2888
  to_port                  = 2888
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.zk_sg.id
}

resource "aws_launch_configuration" "zk_lc" {
  count = var.zookeeper_count

  name_prefix   = "${local.zk_lc_name_prefix}${count.index}-"
  image_id      = local.zk_ami_id
  instance_type = var.zookeeper_instance_type

  user_data = element(data.template_file.zk_user_data.*.rendered, count.index)

  key_name             = var.deployment_ssh_key
  iam_instance_profile = aws_iam_instance_profile.instance_profile.name

  security_groups = local.zk_allowed_sgs

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "zk_asg" {
  count = var.zookeeper_count

  name_prefix          = "${local.zk_asg_name_prefix}${count.index}-"
  launch_configuration = element(aws_launch_configuration.zk_lc.*.name, count.index)

  vpc_zone_identifier = [element(var.subnet_ids, count.index)]

  default_cooldown          = 0
  health_check_grace_period = 30

  desired_capacity = 1
  max_size         = 1
  min_size         = 1

  tags = concat(local.zk_asg_tags,
    [
      {
        key                 = "Name"
        value               = "${local.zk_resource_prefix}${count.index}"
        propagate_at_launch = true
      },
      {
        key                 = "uuid"
        value               = element(random_uuid.zk_uuid.*.result, count.index)
        propagate_at_launch = true
      },
      {
        key                 = "deployment-name"
        value               = var.deployment_name
        propagate_at_launch = true
      },
  ])
}
