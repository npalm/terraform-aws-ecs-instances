## EC2

resource "aws_autoscaling_group" "ecs_instance" {
  name                      = "${var.environment}-as-group"
  vpc_zone_identifier       = "${var.subnets}"
  min_size                  = "${var.asg_min}"
  max_size                  = "${var.asg_max}"
  desired_capacity          = "${var.asg_desired}"
  health_check_grace_period = 300
  launch_configuration      = "${aws_launch_configuration.ecs_instance.name}"

  tag {
    key                 = "Name"
    value               = "${var.environment}-ecs-cluster"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = "${var.environment}"
    propagate_at_launch = true
  }
}

data "aws_ami" "aws_optimized_ecs" {
  most_recent = true # get the latest version

  filter {
    name = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"] # ECS optimized image
  }

  owners = [
    "amazon" # Only official images
  ]
}

data "aws_ami" "stable_coreos" {
  most_recent = true # get the latest version

  filter {
    name = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"] # ECS optimized image
  }

  owners = [
    "amazon" # Only official images
  ]
}

data "template_file" "cloud_config" {
  template = "${file("${path.module}/user_data/core-os-cloud-config.yml")}"

  vars = {
    aws_region         = "${var.aws_region}"
    ecs_cluster_name   = "${var.ecs_cluster_name}"
    ecs_log_level      = "info"
    ecs_agent_version  = "1.61.3"
    ecs_log_group_name = "${aws_cloudwatch_log_group.ecs.name}"
  }
}

data "template_file" "ecs_linux" {
  template = "${file("${path.module}/user_data/amzl-user-data.tpl")}"

  vars = {
    ecs_cluster_name   = "${var.ecs_cluster_name}"
    ecs_log_group_name = "${aws_cloudwatch_log_group.ecs.name}"
  }
}

locals {
  coreos_ami_userdefined = "${lookup(var.coreos_amis, var.aws_region, "")}"
  coreos_ami             = "${local.coreos_ami_userdefined == "" ? data.aws_ami.stable_coreos.id : local.coreos_ami_userdefined}"
}

locals {
  aws_ami_userdefined = "${lookup(var.ecs_optimized_amis, var.aws_region, "")}"
  aws_ami             = "${local.aws_ami_userdefined == "" ? data.aws_ami.aws_optimized_ecs.id : local.aws_ami_userdefined}"
}

locals {
  user_data_aws    = "${var.user_data == "" && var.os != "coreos" ? data.template_file.ecs_linux.rendered : var.user_data}"
  user_data_coreos = "${var.user_data == "" && var.os == "coreos" ? data.template_file.cloud_config.rendered : var.user_data}"
}

resource "aws_launch_configuration" "ecs_instance" {
  security_groups      = ["${aws_security_group.instance_sg.id}"]
  key_name             = "${var.key_name}"
  image_id             = "${var.os == "coreos" ? "${local.coreos_ami}" : "${local.aws_ami}"}"
  user_data            = "${var.os == "coreos" ? "${local.user_data_coreos}" : "${local.user_data_aws}"}"
  instance_type        = "${var.instance_type}"
  iam_instance_profile = "${aws_iam_instance_profile.ecs_instance.name}"

  associate_public_ip_address = false

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "instance_sg" {
  name        = "${var.environment}-ecs-cluster-sg"
  description = "controls access to ecs-cluster instances"
  vpc_id      = "${var.vpc_id}"

  ingress {
    protocol  = "tcp"
    from_port = 0
    to_port   = 65535

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags  = {
    Name        = "${var.environment}-ecs-cluster-sg"
    Environment = "${var.environment}"
  }
}

resource "aws_iam_instance_profile" "ecs_instance" {
  name_prefix = "${var.environment}-ecs-instance-profile"
  role = "${aws_iam_role.ecs_instance.name}"
}

data "template_file" "instance_role_trust_policy" {
  template = "${file("${path.module}/policies/instance-role-trust-policy.json")}"
}

resource "aws_iam_role" "ecs_instance" {
  name_prefix = "${var.environment}-ecs-instance-role"
  assume_role_policy = "${data.template_file.instance_role_trust_policy.rendered}"
}

data "template_file" "instance_profile" {
  template = "${file("${path.module}/policies/instance-profile-policy.json")}"
}

resource "aws_iam_role_policy" "ecs_instance" {
  name_prefix   = "${var.environment}-ecs-instance-role"
  role   = "${aws_iam_role.ecs_instance.name}"
  policy = "${data.template_file.instance_profile.rendered}"
}

## CloudWatch Logs

resource "aws_cloudwatch_log_group" "ecs" {
  name = "${var.environment}-ecs-group/ecs-agent"

  tags = {
    Name        = "${var.environment}-ecs-cluster-sg"
    Environment = "${var.environment}"
  }
}
