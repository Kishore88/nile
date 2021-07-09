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

variable "broker_names" {
  type        = list(string)
  description = "An array of client names to be used for certs"
}

variable "cn_suffix" {
  type        = string
  description = "CN suffix, eg: kafka.dev.foobar.io"
}

variable "organization" {
  type        = string
}

variable "validity_hours" {
  default = 240000
}

variable "dns_zone_id" {
  type        = string
  description = "DNS Zone id for acme challenge"
}

variable "aws_region" {
  type = string
  default = "eu-west-1"
}

variable "acme_staging_url" {
  type = string
  description = "url of Let's Encrypt staging endpoint"
  default = "https://acme-staging-v02.api.letsencrypt.org/directory"
}

variable "acme_prod_url" {
  type = string
  description = "url of Let's Encrypt prod endpoint"
  default = "https://acme-v02.api.letsencrypt.org/directory"
}

variable "dns_nameserver" {
  type = string
  description = "DNS resolver to check for propagation of the TXT record for acme challenge"
  default = "8.8.8.8:53"
}

variable "dns_acme_ttl" {
  type = number
  description = "ttl for dns chanllenge TXT records"
  default = 30
}

variable "dns_acme_timeout" {
  type = number
  description = "timeout of TXT record propagation"
  default = 300
}

variable "dns_acme_polling_interval" {
  type = number
  description = "polling interval for TXT record propagation"
  default = 30
}

variable "route53_endpoint" {
  type        = string
  description = "route 53 endpoint"
}

variable "email_address" {
  description = "email address used for the broker certificates"
  type        = string
}
