# AWS Terraform module to create ECS cluster instances.

This modules creates EC2 instances for a ECS cluster using autoscaling groups. The following features are supported.
- Supports both Amazon linux and CoreOS.
- Instances logging streamed to AWS CloudWatch for Amazon Linux.
- ECS agent enabled for AWS CloudWatch.


## Example usages:
```
### Create a VPC.
locals {
  environment = "dev"
  key_name = "dev-key"
}

module "vpc" {
  source  = "npalm/vpc/aws"
  version = "1.1.0"

  environment = "${local.environment}"
  aws_region  = "${var.aws_region}"

  create_private_hosted_zone = "false"

  // example to override default availability_zones
  availability_zones = {
    eu-west-1 = ["eu-west-1a", "eu-west-1b"]
  }
}

### Create a key pair
resource "aws_key_pair" "key" {
  key_name   = "${var.key_name}"
  public_key = "${file("id_rsa.pub")}"
}

resource "aws_ecs_cluster" "cluster" {
  name = "${var.environment}-ecs-cluster"
}

module "ecs-instances" {
  source  = "npalm/ecs-instances/aws"
  version = "0.1"

  ecs_cluster_name = "${aws_ecs_cluster.cluster.name}"

  aws_region  = "${var.aws_region}"
  environment = "${local.environment}"
  key_name    = "${local.key_name}"

  vpc_id   = "${module.vpc.vpc_id}"
  vpc_cidr = "${module.vpc.vpc_cidr}"
  subnets  = "${module.vpc.private_subnets}"

}


```

# Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| asg_desired | Desired numbers of instances in the auto scaling group. | string | `1` | no |
| asg_max | Maximum numbers of instances in the auto scaling group. | string | `2` | no |
| asg_min | Minimum numbers of instances in the auto scaling group. | string | `1` | no |
| aws_region | The AWS region to be used. | string | - | yes |
| coreos_amis | A map of region to core os AMI. By default the latest available will be chosen. | map | `<map>` | no |
| ecs_cluster_name | Name of the ECS cluster. | string | - | yes |
| ecs_optimized_amis | A map of region to ecs optimized AMI. By default the latest available will be chosen. | map | `<map>` | no |
| environment | Logical name of the environment, will be used as prefix and in tags. | string | - | yes |
| instance_type | Default AWS instance type. | string | `t2.small` | no |
| key_name | Name of AWS key pair | string | - | yes |
| os | By default Amazon linux is used, other supported OS in CoreOS. | string | `` | no |
| subnets | Subnets where the instances will be deployed to. | list | - | yes |
| vpc_cidr | CIDR for the VPC. | string | - | yes |
| vpc_id | ID of the VPC. | string | - | yes |
