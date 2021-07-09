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
variable "deployment_name" {
  type        = string
  description = "Name of the deployment"
}

variable "deployment_region" {
  type        = string
  description = "AWS region to use"
}

variable "deployment_ssh_key" {
  type        = string
  description = "SSH key name for the deployment"
}

variable "deployment_tags" {
  type        = map(string)
  description = "Map of tag to append to all the resource of the deployment"
}

variable "env" {
  type        = string
  description = "environment in which the cluster is deployed, eg: 'dev'"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID of to use for the deployment"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs to use for the instances"
}

variable "base_sg_cidr_allowed" {
  type        = list(string)
  description = "List of CIDRs allowed to IGRESS traffic to base SG"
}

variable "broker_ami_id" {
  type        = string
  default     = ""
  description = "Kafka Broker AMI ID"
}

variable "broker_count" {
  type        = number
  description = "Number of Kafka Broker instances"
}

variable "broker_instance_type" {
  type        = string
  default     = "m5.large"
  description = "Kafka Broker instance type"
}

variable "broker_sg_cidr_allowed" {
  type        = list(string)
  description = "List of CIDRs allowed to IGRESS traffic to broker SG"
}

variable "broker_allowed_sgs" {
  type        = list(string)
  description = "Allowed SGs to speak with Kafka Broker instances"
}

variable "zookeeper_ami_id" {
  type        = string
  default     = ""
  description = "Zookeeper AMI ID"
}

variable "zookeeper_count" {
  type        = number
  description = "Number of Kafka Broker instances"
}

variable "zookeeper_instance_type" {
  type        = string
  default     = "m5.large"
  description = "Zookeeper instance type"
}

variable "zookeeper_allowed_sgs" {
  type        = list(string)
  description = "Allowed SGs to speak with Zookeeper instances"
}

variable "zookeeper_volume_size" {
  type        = number
  default     = 200
  description = "Size of the Zookeeper's EBS volume for the data in GB"
}

variable "prometheus_sg_id" {
  type        = string
  description = "Prometheus security group id"
  default     = null
}

variable "ami_kfk_prefix" {
  type        = string
  default     = ""
  description = "The prefix to be use for AMI search when AMI_ID is not specified."
}

variable "ami_zk_prefix" {
  type        = string
  default     = ""
  description = "The prefix to be use for AMI search when AMI_ID is not specified."
}

variable "els_endpoint" {
  type        = string
  default     = ""
  description = "The https endpoint to reach ElasticSearch service to index the logs"
}

variable "broker_sasl_port" {
  type        = number
  default     = 9094
  description = "Broker SASL_SSL Port for the clients to connect to the brokers"
}

variable "broker_ssl_port" {
  type        = number
  default     = 9093
  description = "Broker SSL Port for the clients to connect to the brokers"
}

variable "broker_pt_port" {
  type        = number
  default     = 9092
  description = "Broker Plaintext Port for the clients to connect to the brokers"
}

variable "broker_volume_size" {
  type        = number
  default     = 1024
  description = "Size of the Broker's EBS volume for the data in GB"
}

variable "broker_message_max_bytes" {
  type        = number
  default     = 10000012
  description = "Sets message.max.bytes for the brokers"
}

variable "ca_key" {
  type        = string
  description = "actual string of the CA key"
  default     = null
}

variable "ca_cert" {
  type        = string
  description = "actual string of the CA cert"
  default     = null
}

variable "admin_users_ids" {
  type        = list(string)
  description = "Users ids allowed to access the secure bucket"
}

variable "security_interbroker_security_enabled" {
  type        = bool
  description = "Enable interbroker security"
  default     = true
}

variable "security_additional_super_users_subjects" {
  type        = list(string)
  description = "Additional kafka super users"
  default     = []
}

variable "security_broker_client_allow_anyone" {
  type        = bool
  description = "Allow clients to connect without authentication/security"
  default     = false
}

variable "dns_zone" {
  type        = string
  description = "DNS Zone to register the cluster subzone and broker records"
}

variable "app_names" {
  type        = list(string)
  description = "Names of the applications which will interact with the cluster"
}

variable "organization" {
  type        = string
  description = "Organization used for the certificate subject"
}

variable "broker_inter_broker_protocol_version" {
  type        = string
  description = "The inter.broker.protocol.version to use. Important during upgrade"
  default     = "2.3"
}


variable "ingress_elb_subnet_ids" {
  description = "Subnets to use for the ingress ELB for the containerised components (Schema-registry, kafka-connect)"
}

variable "email_address" {
  description = "email address used for the broker certificates"
  type        = string
}


################################################################################
##                                                                            ##
##                 ----==| S C H E M A   R E G I S T R Y |==----              ##
##                                                                            ##
################################################################################

variable "schema_registry_enabled" {
  type        = bool
  description = "wether the schema registry should be setup as well"
  default     = true
}

variable "eks_lb_zone_id" {
  description = "elb host zone id from : https://docs.aws.amazon.com/general/latest/gr/rande.html#elb_region"
  default     = ""
}

variable "schema_registry_eks_name" {
  type        = string
  description = "eks cluster where schema registry will be deployed"
}

variable "schema_registry_app_name" {
  type    = string
  default = "schema-registry"
}

variable "schema_registry_app_scram_password" {
  description = "scram password for schema registry app"
  default     = "to be set"
}

variable "sr_eks_namespace" {
  default = "kafka"
}

variable "schema_registry_replica_count" {
  default = 2
}

variable "schema_registry_image" {
  default = "confluentinc/cp-schema-registry"
}

variable "schema_registry_tag" {
  default = "5.4.0"
}

variable "schema_registry_container_mem_limit" {
  default = "1000M"
}

variable "schema_registry_container_cpu_limit" {
  default = "500m"
}

variable "schema_registry_container_mem_req" {
  default = "1000M"
}

variable "schema_registry_container_cpu_req" {
  default = "500m"
}

variable "schema_registry_healthcheck_interval" {
  default = 32
}

################################################################################
##                                                                            ##
##                 ----==| K A F K A   C O N N E C T |==----                  ##
##                                                                            ##
################################################################################

variable "kafka_connect_enabled" {
  description = "Enable kafka-connect?"
  type        = bool
  default     = false
}

variable "kafka_connect_image_url" {
  description = "image url of kafka connect to deploy"
  default     = "not installed"
}

variable "kafka_connect_image_tag" {
  description = "kafka connect image tag"
  default     = "not installed"
}

variable "kafka_connect_replica_count" {
  default = 2
}

variable "kafka_connect_container_mem_limit" {
  default = "5000M"
}

variable "kafka_connect_container_mem_req" {
  default = "5000M"
}

variable "kafka_connect_container_cpu_limit" {
  default = "1500m"
}

variable "kafka_connect_container_cpu_req" {
  default = "750m"
}

variable "kafka_connect_healthcheck_image_url" {
  description = "image kafka connect health check"
  default     = "not installed"
}

variable "kafka_connect_healthcheck_image_tag" {
  description = "image tag kafka connect health check"
  default     = "not installed"
}

variable "kafka_connect_healthcheck_enabled" {
  default = true
}

variable "kafka_connect_healthcheck_interval" {
  default = 300
}

variable "kafka_connect_healthcheck_timeout" {
  default = 15
}

variable "kafka_connect_healthcheck_failure_threshold" {
  default = 3
}

variable "kafka_connect_healthcheck_success_threshold" {
  default = 1
}

variable "kafka_connect_hearbeat_interval" {
  default = 10000
}

variable "kafka_connect_session_timeout" {
  default = 60000
}

variable "kafka_connect_app_scram_password" {
  description = "scram password for kafka connect app"
  default     = "to be specified"
}

variable "kafka_connect_jmx_exporter" {
  default = false
}

variable "kafka_connect_healthcheck_pg_endpoint" {
  description = "endpoint used by kafka connect health check to push metrics - only supported for kafka connect healthcheck version > 0.1.8 for prior version this variable is ignored"
  default = "local"
}
################################################################################
##                                                                            ##
##                         ----==| S C R A M |==----                          ##
##                                                                            ##
################################################################################

variable "security_scram_dynamodb_table_name_prefix" {
  type        = string
  description = "DynamoDB table name prefix for the SCRAM store, eg:'Kafka'"
  default     = ""
}

variable "security_scram_handler" {
  type        = string
  description = "ARN of the dynamodb table used for the scram credentials store, eg: 'arn:aws:dynamodb:eu-west-1:123456:table/KafkaScramTable'"
  default     = "kafka_dynamodb_store.scram.CallbackHandler"
}

variable "security_scram_mechanisms" {
  type        = list(string)
  description = "SCRAM mechanisms enabled, eg: SCRAM-SHA-512"
  default     = ["SCRAM-SHA-256", "SCRAM-SHA-512"]
}

################################################################################
##                                                                            ##
##                 ----==| K A F K A   W A T C H D O G |==----                ##
##                                                                            ##
################################################################################

variable "kafka_watchdog_enabled" {
  description = "Enable kafka-watchdog?"
  type        = bool
  default     = false
}

variable "kafka_watchdog_cfg_env" {
  description = "env for kafka watchdog 1 config"
  type        = string
  default     = "dev"
}

variable "kafka_watchdog_image_url" {
  description = "image url of kafka watchdog to deploy"
  default     = "not installed"
}

variable "kafka_watchdog_image_tag" {
  description = "image tag of kafka watchdog to deploy"
  default     = "not installed"
}

variable "kafka_watchdog_config_key" {
  description = " arn of the encryption key for kafka watchdog config"
  default     = "not installed"
}

variable "kafka_watchdog_eks_role_name" {
  description = " name of the role (eks ec2 instance role) to attach kafka watchdog policy to"
  default     = "not installed"
}

variable "kafka_watchdog_container_mem_limit" {
  default = "500M"
}

variable "kafka_watchdog_container_cpu_limit" {
  default = "250m"
}

variable "kafka_watchdog_container_mem_req" {
  default = "500M"
}

variable "kafka_watchdog_container_cpu_req" {
  default = "100m"
}


################################################################################
##                                                                            ##
##                ----==| U S E R S   &   T O P I C S |==----                 ##
##                                                                            ##
################################################################################


variable "topics" {
  type = list(object({
    name               = string
    partitions         = number
    replication_factor = number
    config             = map(string)
  }))
  default = []
}

variable "topics_allow_deletion" {
  type        = bool
  description = "Allow deletion of topics across the cluster (delete.topic.enable)"
  default     = true
}


variable "users_acls" {
  type = list(object({
    name = string
    write_access = list(object({
      topic_prefix = string
    }))
    delete_access = list(object({
      topic_prefix = string
    }))
  }))
  default = []
}

variable "users" {
  type = list(object({
    name     = string
    password = string
  }))
  default = []
}

variable "terraform_kafka_user" {
  type        = string
  description = "Kafka user to be used while performing operations on the kafka brokers (topics creation, acls, ...)"
  default     = "ops-terraform"
}

variable "terraform_kafka_user_password" {
  type        = string
  description = "Kafka user password to be used while performing operations on the kafka brokers (topics creation, acls, ...)"
}

variable "terraform_kafka_mechanism" {
  type        = string
  description = "SCRAM mechanism to be used while performing operations on the kafka brokers (topics creation, acls, ...)"
  default     = "scram-sha512"
}



################################################################################
##                                                                            ##
##       ----==| N O N   S T A N D A R D   P A R T I T I O N S |==----        ##
##                                                                            ##
################################################################################

variable "aws_partition" {
  type        = string
  description = "AWS partition, eg 'aws', 'aws-cn',..."
  default     = "aws"
}

variable "aws_ec2_service_identifier" {
  type        = string
  description = "ec2 service identifier, eg 'ec2.amazonaws.com.cn' for china"
  default     = "ec2.amazonaws.com"
}


variable "route53_endpoint" {
  type        = string
  description = "route 53 endpoint, set to null to use the default one"
  default     = null
}
