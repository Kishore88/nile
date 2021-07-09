# Kafka cluster - terraform module

Terraform module to deploy a robust Kafka Cluster on AWS in a VPC environment.

## Requirements
  * sops terraform provider installed in `.terraform/plugins`
  * kafka terraform provider (https://github.com/Mongey/terraform-provider-kafka) installed in `.terraform/plugins`

## Description

  * Brokers and zookeeper nodes are fault tolerant and they recover
    automatically (using ASG min:1, max:1)
  * On failure it automatically recreated the instance and re-attach
    the correct EBS volume (tagged with UUID)
  * Storage is in Encrypted EBS volumes
  * Each broker uses 2 NICs, one automatically assigned (private IP), one with fix
    IP and used as advertised host
  * Let's encrypt is used to generate the entries for the advertised host
  * Memory is automatically set to be 60% of host total memory or 1Gib
    (which one is greater)
  * It uses JDK12 with the new Shenandoah GC (installed as `/usr/lib/jvm/master-java`)
  * For metering and alerts host-level metrics as well as broker
    metrics are exposed to Prometheus
  * Logs are pushed to ElasticSearch/Kibana
  * Kafka brokers and Zookeepers peers can be configured with
    environment variables in `user-data`
  * The clients can use SASL_SCRAM and the credentials can be managed with (https://github.com/obohrer/kafka-dynamodb-store)
  * Support deployments of schema-registry & kafka-connect if provided with an eks cluster


## Build images

  * install packer
  ```
  brew install packer
  ```

  * set your AWS environment
  ```
  export AWS_PROFILE=xxx
  ```

  * if you are working on a specific environment or you wish to create
    a set of images for a specific test then use a `ami_prefix`, use
    the same prefix for the `terraform apply`.
  ```
  export TF_VAR_ami_prefix=mytest-
  ```

  * build zookeeper
  ```
  cd packer
  packer build zookeeper.json
  ```

  * build kafka
  ```
  cd packer
  packer build kafka.json
  ```


## Configuration

The Kafka brokers as well as the Zookeeper nodes can be configured via
environment variables in the EC2's `user-data`.

### Kafka Broker configuration

The default configuration template is in
[./packer/resources/kafka.properties.tmpl](./packer/resources/kafka.properties.tmpl).
Additional options (or overwriting the one already provided) can be
done by adding additional environment variables in the
[./module/templates/kafka-user-data.tpl](./module/templates/kafka-user-data.tpl).

For example to add the default compression add:

``` bash
#
# ENTER HERE YOUR CUSTOM CONFIGURATION OPTIONS FOR KAFKA
# PREFIX: KFKCFG_
#
export KFKCFG_COMPRESSION_TYPE=lz4
export KFKCFG_NUM_PARTITIONS=2
```

When the instance boots-up the configuration template will be rendered
and the above options will be added as follow in the
`/etc/kafka/kafka.properties` file.

``` text
#
# USER CONFIG
#
compression.type=lz4
num.partitions=2
```

In other words, any environment variable which is added with the
`KFKCFG_` prefix is converted to a Kafka option and every underscore
`_` is turned into a dot (`.`).



### Zookeeper node configuration

The default configuration template is in
[./packer/resources/zookeeper.properties.tmpl](./packer/resources/zookeeper.properties.tmpl).
Additional options (or overwriting the one already provided) can be
done by adding additional environment variables in the
[./module/templates/zk-user-data.tpl](./module/templates/zk-user-data.tpl).

For example to change `minSessionTimeout` and `tickTime` add:

``` bash
#
# ENTER HERE YOUR CUSTOM CONFIGURATION OPTIONS FOR ZOOKEEPER
# PREFIX: ZKCFG_
#
export ZKCFG_MIN_SESSION_TIMEOUT=10000
export ZKCFG_TICK_TIME=2500
```

When the instance boots-up the configuration template will be rendered
and the above options will be added as follow in the
`/etc/zookeeper/zookeeper.properties` file.

``` text
#
# USER CONFIG
#
minSessionTimeout=10000
tickTime=2500
```

In other words, any environment variable which is added with the
`ZKCFG_` prefix is converted to a Zookeeper option and every underscore
`_` is eliminated and the next word is capitalised.


For more information please see: [Synapse](https://github.com/BrunoBonacci/synapse)

## Deploy


```
variable "ami_prefix" {
  type        = "string"
  default     = ""
  description = "The prefix to be use for AMI search when AMI_ID is not specified."
}

module "kafka_deployment_testing" {
  source = "module"

  ami_prefix            = "${var.ami_prefix}"
  deployment_name       = "kafka-testing"
  deployment_region     = "eu-west-1"
  deployment_ssh_key    = "ec2-keypair"
  subnet_ids            = "${data.aws_subnet_ids.subnets.ids}"
  vpc_id                = "vpc-12345678"
  broker_allowed_sgs    = []
  broker_count          = 3
  zookeeper_allowed_sgs = []
  zookeeper_count       = 3

  base_sg_cidr_allowed   = ["0.0.0.0/0"]
  broker_sg_cidr_allowed = ["0.0.0.0/0"]
  email_address          = "emailAddressForCerts@foobar.foo"
  #els_endpoint          = "https://vpc-elstest-inb7p7ebxikmmrxrdasdjklajd.eu-west-1.es.amazonaws.com"
  #prometheus_sg_id      = "sg-cafeee"
  admin_users_ids       = ["aws-user-unique-id-for-the-admin"]
  dns_zone              = "basedns-zone-for-cluster.foobar.io"

  organization          = "kafka-testing-org"

  deployment_tags = {
    chaos-testing = "opt-in"
    environment   = "dev"
  }
}
```


### Kafka tools deploy

Kafka tools is an instance with containing the Confluent platform
tools and kafkcat (and other cmd line tools). It can be used to connect
to one or more clusters and perform admin operations or data analysis.

```
module "kafka-tools" {
  source = "tools-module/"

  security_groups = ["sg-xyz123"]
  keypair_name    = "your-keypair"
  vpc_subnets     = ["subnet-aaa123", "subnet-bbb123", "subnet-ccc123"]

  tags = { chaos-testing = "opt-in"}
}
```

NOTE: the base image is an Ubuntu 18.04, therefore use the `ubuntu`
user when connecting to the instance.

## Operations

### How to extend the size of the storage volume

  - Increase the size of the EBS volumes using the appropriate
    variables `broker_volume_size` and `zookeeper_volume_size`
  - Apply the changes via `terraform apply`. Please note that the
    change is **non destructive** so it can be applied without any
    problem to all volumes at once.
  - Once the volumes are updated, ssh into each node and run the
    following commands to extends the partition and the filesystem
    ```
    ## identify the partition to extend
    lsblk

    # extend partition 1
    sudo growpart /dev/nvme1n1 1

    # resize filesystem
    sudo xfs_growfs -d /var/lib/kafka

    # check
    df -h
    ```
    Now it should show the volumes with the new size


## Troubleshooting

### SOPS errors

if you get the following error:

``` text
Error: Error getting data key: 0 successful groups required, got 0

  on main.tf line 38, in data "sops_file" "secrets":
  38: data "sops_file" "secrets" {
```

try to run:

``` bash
$ sops --verbose secrets.json
Failed to get the data key required to decrypt the SOPS file.

Group 0: FAILED
  arn:aws:kms:eu-west-1:123456789012:key/a6dbefff-ccbe-4811-912b-abcd4e0bdbf0f: FAILED
    - | Error decrypting key: UnrecognizedClientException: The
      | security token included in the request is invalid.
      |     status code: 400, request id:
      | 0abcf170-9c98-417c-abcd-61c2282539af
```

If the output look like the above then add:
``` bash
export AWS_SDK_LOAD_CONFIG=1
```



## Authors and contributors

Authors and contributors _(in alphabetic order)_

  - Bruno Bonacci ([@BrunoBonacci](https://github.com/BrunoBonacci))
  - Darren Bishop ([@DarrenBishop](https://github.com/DarrenBishop))
  - Kishore Kumar Suthar ([@Kishore88](https://github.com/Kishore88))
  - Iacopo I.
  - Olivier Bohrer ([@obohrer](https://github.com/obohrer))
  - Sathyavijayan Vittal ([@sathyavijayan](https://github.com/sathyavijayan))
  - Yacine Chantit ([@ychantit](https://github.com/ychantit))

## License

Copyright © 2020-2021 VIOOH Ltd

Distributed under the Apache License v 2.0 (http://www.apache.org/licenses/LICENSE-2.0)
