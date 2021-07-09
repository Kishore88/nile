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
data "aws_iam_policy_document" "instances_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = [var.aws_ec2_service_identifier]
    }
  }
}

resource "aws_iam_role" "instance_role" {
  name               = "${var.deployment_name}-kafka-instance-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.instances_role.json
}

data "aws_iam_policy_document" "instance_policy" {
  statement {
    sid = "AttachVolume"

    actions = [
      "ec2:AttachVolume",
      "ec2:DescribeVolumes",
    ]

    resources = ["*"]
  }

  statement {
    sid = "AttachNetworkInterfaces"

    actions = [
      "ec2:AttachNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
    ]

    resources = ["*"]
  }

  statement {
    sid = "DescribeInstancesTags"

    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeTags",
    ]

    resources = ["*"]
  }

  statement {
    sid = "S3"

    actions = [
      "s3:ListBucket",
      "s3:GetObject",
    ]

    resources = [
      "arn:${var.aws_partition}:s3:::${aws_s3_bucket.certs.bucket}",
      "arn:${var.aws_partition}:s3:::${aws_s3_bucket.certs.bucket}/*",
    ]
  }

  statement {
    sid = "SCRAMDynamoDB"

    actions = [
      "dynamodb:GetItem",
    ]

    resources = [
      aws_dynamodb_table.scram_store.arn
    ]
  }

}

resource "aws_iam_policy" "instances_policy" {
  name        = "${var.deployment_name}-kafka-instances-policy"
  path        = "/"
  description = "Policy for EC2 instances role of ${var.deployment_name} Kafka deployment"

  policy = data.aws_iam_policy_document.instance_policy.json
}

resource "aws_iam_role_policy_attachment" "intances_role_policy_attachment" {
  policy_arn = aws_iam_policy.instances_policy.arn
  role       = aws_iam_role.instance_role.name
}

resource "aws_iam_role_policy_attachment" "instances_role_policy_attachment_ssm" {
  policy_arn = "arn:${var.aws_partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.instance_role.name
}


resource "aws_iam_instance_profile" "instance_profile" {
  name = "${var.deployment_name}-instance-profile"
  role = aws_iam_role.instance_role.name
}
