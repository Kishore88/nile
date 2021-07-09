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
provider "acme" {
  server_url = var.acme_prod_url
}

provider "tls" {}

locals {
  broker_common_names = formatlist("%s.${var.cn_suffix}", var.broker_names)
  broker_subjects = formatlist("User:CN=%s",local.broker_common_names)
}

resource "tls_private_key" "acme_reg_private_key" {
  algorithm = "RSA"
}

resource "acme_registration" "acme_reg" {
  account_key_pem = tls_private_key.acme_reg_private_key.private_key_pem
  email_address   = var.email_address
}

################################################################################
##                                                                            ##
##                       ----==| B R O K E R S |==----                        ##
##                                                                            ##
################################################################################

resource "tls_private_key" "brokers_pk" {
  count = length(var.broker_names)

  algorithm = "RSA"
}

resource "tls_cert_request" "brokers_cert_rq" {
  count = length(var.broker_names)

  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.brokers_pk[count.index].private_key_pem

  subject {
    common_name  = local.broker_common_names[count.index]
    organization = var.organization
  }
}

resource "acme_certificate" "brokers_acme_cert" {
  count = length(var.broker_names)

  account_key_pem         = acme_registration.acme_reg.account_key_pem
  certificate_request_pem = tls_cert_request.brokers_cert_rq[count.index].cert_request_pem
  recursive_nameservers = [var.dns_nameserver]

  dns_challenge {
    provider = "route53"
    config = {
      AWS_DEFAULT_REGION      = var.aws_region
      AWS_HOSTED_ZONE_ID      = var.dns_zone_id
      AWS_TTL                 = var.dns_acme_ttl
      AWS_PROPAGATION_TIMEOUT = var.dns_acme_timeout
      AWS_POLLING_INTERVAL    = var.dns_acme_polling_interval
      endpoint                = var.route53_endpoint
    }
  }
}
