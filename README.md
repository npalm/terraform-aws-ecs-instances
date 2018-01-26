# AWS Terraform module to create ECS cluster instances.

This modules creates EC2 instances for a ECS cluster using autoscaling groups. The following features are supported.
- Supports both Amazon linux and CoreOS.
- Instances logging streamed to AWS CloudWatch for Amazon Linux.
- ECS agent enabled for AWS CloudWatch.
- Option to override the provided user data.


## Example usages:
```
locals {
  aws_region  = "eu-west-1"
  environment = "dev"
  key_name    = "dev-key"
}

provider "aws" {
  region  = "${local.aws_region}"
  version = "1.7.1"
}

module "vpc" {
  source  = "npalm/vpc/aws"
  version = "1.1.0"

  environment = "${local.environment}"
  aws_region  = "${local.aws_region}"

  create_private_hosted_zone = "false"

  availability_zones = {
    eu-west-1 = ["eu-west-1a", "eu-west-1b"]
  }
}

### Create a key pair
resource "aws_key_pair" "key" {
  key_name   = "${local.key_name}"
  public_key = "${file("id_rsa.pub")}"
}

resource "aws_ecs_cluster" "cluster" {
  name = "${local.environment}-ecs-cluster"
}

# AWS linux
module "ecs-instances-aws" {
  source  = "npalm/ecs-instances/aws"

  ecs_cluster_name = "${aws_ecs_cluster.cluster.name}"

  aws_region  = "${local.aws_region}"
  environment = "${local.environment}"
  key_name    = "${local.key_name}"

  vpc_id   = "${module.vpc.vpc_id}"
  vpc_cidr = "${module.vpc.vpc_cidr}"
  subnets  = "${module.vpc.private_subnets}"

}

# CoreOS
module "ecs-instances-aws" {
  source  = "npalm/ecs-instances/aws"

  ecs_cluster_name = "${aws_ecs_cluster.cluster.name}"

  aws_region  = "${local.aws_region}"
  environment = "${local.environment}"
  key_name    = "${local.key_name}"

  vpc_id   = "${module.vpc.vpc_id}"
  vpc_cidr = "${module.vpc.vpc_cidr}"
  subnets  = "${module.vpc.private_subnets}"

  os = "coreos"
}

```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| asg_desired | Desired numbers of instances in the auto scaling group. | string | `1` | no |
| asg_max | Maximum numbers of instances in the auto scaling group. | string | `2` | no |
| asg_min | Minimum numbers of instances in the auto scaling group. | string | `1` | no |
| aws_region | The AWS region to be used. | string | - | yes |
| coreos_amis | A map of region to core os AMI. By default the latest available will be chosen. | map | `<map>` | no |
| create_ecs_service_role | If true creates a ECS service role. | string | `true` | no |
| ecs_cluster_name | Name of the ECS cluster. | string | - | yes |
| ecs_optimized_amis | A map of region to ecs optimized AMI. By default the latest available will be chosen. | map | `<map>` | no |
| environment | Logical name of the environment, will be used as prefix and in tags. | string | - | yes |
| instance_type | Default AWS instance type. | string | `t2.small` | no |
| key_name | Name of AWS key pair | string | - | yes |
| os | By default Amazon linux is used, other supported OS in CoreOS. | string | `` | no |
| subnets | Subnets where the instances will be deployed to. | list | - | yes |
| user_data | Override the module embedded user data script. | string | `` | no |
| vpc_cidr | CIDR for the VPC. | string | - | yes |
| vpc_id | ID of the VPC. | string | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| service_role_arn | ARN of IAM role for the ecs agent. |
