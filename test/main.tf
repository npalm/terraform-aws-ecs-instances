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

module "ecs-instances" {
  source = ".."

  ecs_cluster_name = "${aws_ecs_cluster.cluster.name}"

  aws_region  = "${local.aws_region}"
  environment = "${local.environment}"
  key_name    = "${local.key_name}"

  vpc_id   = "${module.vpc.vpc_id}"
  vpc_cidr = "${module.vpc.vpc_cidr}"
  subnets  = "${module.vpc.private_subnets}"
}
