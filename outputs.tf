output "service_role_arn" {
  description = "ARN of IAM role for the ecs agent."
  value       = "${element(concat(aws_iam_role.ecs_service_role.*.arn, list("")), 0)}"
}
