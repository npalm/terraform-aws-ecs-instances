variable "aws_region" {
  description = "The AWS region to be used."
  type        = "string"
}

variable "key_name" {
  description = "Name of AWS key pair"
  type        = "string"
}

variable "instance_type" {
  default     = "t2.small"
  description = "Default AWS instance type."
  type        = "string"
}

variable "asg_min" {
  description = "Minimum numbers of instances in the auto scaling group."
  default     = "1"
  type        = "string"
}

variable "asg_max" {
  description = "Maximum numbers of instances in the auto scaling group."
  default     = "2"
  type        = "string"
}

variable "asg_desired" {
  description = "Desired numbers of instances in the auto scaling group."
  default     = "1"
  type        = "string"
}

// new
variable "vpc_id" {
  description = "ID of the VPC."
  type        = "string"
}

variable "vpc_cidr" {
  description = "CIDR for the VPC."
  type        = "string"
}

variable "environment" {
  description = "Logical name of the environment, will be used as prefix and in tags."
  type        = "string"
}

variable "subnets" {
  description = "Subnets where the instances will be deployed to."
  type        = "list"
}

variable "coreos_amis" {
  description = "A map of region to core os AMI. By default the latest available will be chosen."
  type        = "map"
  default     = {}
}

variable "ecs_optimized_amis" {
  description = "A map of region to ecs optimized AMI. By default the latest available will be chosen."
  type        = "map"
  default     = {}
}

variable "os" {
  description = "By default Amazon linux is used, other supported OS in CoreOS."
  default     = ""
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster."
  type        = "string"
}

variable "user_data" {
  description = "Override the module embedded user data script."
  type        = "string"
  default     = ""
}
