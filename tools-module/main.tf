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
  ami_id          = var.ami_id == "" ? data.aws_ami.tools_ami.image_id : var.ami_id
  tools_asg_tags = [for key in keys(var.tags) :
    {
      key                 = key
      value               = var.tags[key]
      propagate_at_launch = true
    }]
}


data "aws_ami" "tools_ami" {
  most_recent = true

  owners     = ["self"]
  name_regex = "${var.ami_prefix}nile-kafka-tools-ubuntu-"
}


module "kafka-tools-asg" {
  source                    = "terraform-aws-modules/autoscaling/aws"
  version                   = "~> 3.0"

  name                      = var.tools_name

  # Launch configuration
  lc_name                   = var.tools_name
  image_id                  = local.ami_id
  instance_type             = var.instance_type
  iam_instance_profile      = var.instance_profile
  security_groups           = var.security_groups
  key_name                  = var.keypair_name
  user_data                 = var.user_data

  # Auto scaling group
  asg_name                  = var.tools_name
  vpc_zone_identifier       = var.vpc_subnets
  health_check_type         = "EC2"
  min_size                  = var.min_instances
  max_size                  = var.max_instances
  desired_capacity          = var.num_instances
  wait_for_capacity_timeout = 0
  default_cooldown          = 300


  root_block_device = [
    {
      volume_size = var.root_disk_size
      encrypted   = true
      volume_type = "gp2"
    },
  ]


  tags                      = local.tools_asg_tags
}
