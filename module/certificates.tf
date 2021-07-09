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
  s3_certs_tags = {}
  s3_certs_name = "nile-kafka-certs-${var.deployment_name}"
  user_ids_json = jsonencode(concat(["${aws_iam_role.instance_role.unique_id}:*"], var.admin_users_ids))
  all_apps      = concat(compact([var.schema_registry_app_name, var.kafka_connect_app_name, var.kafka_watchdog_app_name]), var.app_names)
  cn_suffix     = replace(aws_route53_zone.cluster_brokers_zone.name, "/[.]$/", "")
}

resource "aws_s3_bucket" "certs" {
  bucket = local.s3_certs_name
  acl    = "private"

  tags = merge(var.deployment_tags, local.s3_certs_tags)

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": "arn:${var.aws_partition}:s3:::${local.s3_certs_name}/*",
      "Condition": {
        "StringNotLike": {
          "aws:userId": ${local.user_ids_json}
        }
      }
    }
  ]
}
POLICY
}

resource "aws_s3_bucket_public_access_block" "block_public" {
  bucket = aws_s3_bucket.certs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


module "certificate" {
  source = "./modules/certificate"
  broker_names = aws_route53_record.broker_route53_records.*.name
  // remove trailing dot
  cn_suffix        = local.cn_suffix
  organization     = var.organization
  dns_zone_id      = aws_route53_zone.cluster_brokers_zone.zone_id
  route53_endpoint = var.route53_endpoint
  email_address    = var.email_address
}

resource "aws_s3_bucket_object" "key" {
  count = var.broker_count

  bucket  = aws_s3_bucket.certs.bucket
  key     = "/${count.index}/key"
  content = module.certificate.private_keys[count.index]
}

resource "aws_s3_bucket_object" "cert" {
  count   = var.broker_count
  bucket  = aws_s3_bucket.certs.bucket
  key     = "/${count.index}/cert"
  content = module.certificate.issued_certs_pem[count.index]
}

resource "aws_s3_bucket_object" "ca_cert" {
  bucket  = aws_s3_bucket.certs.bucket
  key     = "ca-cert"
  content = var.ca_cert
}

resource "aws_s3_bucket_object" "cert_issuer" {
  count   = var.broker_count
  bucket  = aws_s3_bucket.certs.bucket
  key     = "/${count.index}/cert-issuer"
  content = module.certificate.broker_issuer_certs[count.index]
}

# aws managed cert for all kafka related endpoint (connetc, schema registry...) behind a load balancer
resource "aws_acm_certificate" "cert_https_sr" {
  domain_name = "${var.deployment_name}.${var.dns_zone}"
  subject_alternative_names = [
    join("", ["*.", "${var.deployment_name}.${var.dns_zone}"])
  ]
  validation_method = "DNS"
}

resource "aws_route53_record" "cert_https_sr_validation" {
  name    = tolist(aws_acm_certificate.cert_https_sr.domain_validation_options)[0].resource_record_name
  type    = tolist(aws_acm_certificate.cert_https_sr.domain_validation_options)[0].resource_record_type
  zone_id = aws_route53_zone.cluster_brokers_zone.id
  records = aws_acm_certificate.cert_https_sr.domain_validation_options.*.resource_record_value
  ttl     = 60
}

resource "aws_acm_certificate_validation" "cert_kafka" {
  certificate_arn         = aws_acm_certificate.cert_https_sr.arn
  validation_record_fqdns = [
    aws_route53_record.cert_https_sr_validation.fqdn
  ]
}
