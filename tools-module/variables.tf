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
variable "security_groups" {
  type        = list
  description = "Security groups for the Kafka tools instance"
}


variable "keypair_name" {
  type        = string
  description = "EC2 keypair name for ssh"
}


variable "vpc_subnets" {
  type        = list
  description = "The list of VPC Subnets for the Kafka tools instance"
}


variable "tools_name" {
  type        = string
  default     = "kafka-tools"
  description = "The name for the ASG, instances for the Kafka toolbox"
}


variable "instance_type" {
  type        = string
  default     = "c5.large"
  description = "Kafka tools instance type"
}


variable "num_instances" {
  type        = number
  default     = 1
  description = "Desired number of instances"
}


variable "min_instances" {
  type        = number
  default     = 0
  description = "Minimum number of instances"
}


variable "max_instances" {
  type        = number
  default     = 2
  description = "Maximum number of instances"
}


variable "ami_prefix" {
  type        = string
  default     = ""
  description = "The prefix to be use for AMI search when AMI_ID is not specified."
}


variable "ami_id" {
  type        = string
  default     = ""
  description = "Kafka tools AMI ID"
}


variable "instance_profile" {
  type        = string
  default     = ""
  description = "Kafka tools instance profile"
}


variable "tags" {
  type        = map(string)
  default     = {name = "kafka-tools"}
  description = "Map of tag to append to all the resource of the deployment"
}


variable "root_disk_size" {
  type        = number
  default     = 250
  description = "Kafka tools instance disk size"
}


variable "user_data" {
  type        = string
  # expected length of user_data to be in the range (1 - 16384)
  default     = " "
  description = "user_data for the ec2 instances"
}
