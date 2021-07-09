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
output "issued_certs_pem" {
  value = acme_certificate.brokers_acme_cert.*.certificate_pem
}

output "broker_issuer_certs" {
  value = acme_certificate.brokers_acme_cert.*.issuer_pem
}

output "private_keys" {
  value = tls_private_key.brokers_pk.*.private_key_pem
}

output "broker_cns" {
  value = local.broker_common_names
}

output "broker_subjects" {
  value = local.broker_subjects
}
