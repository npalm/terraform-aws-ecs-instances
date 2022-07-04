output "service_role_arn" {
  description = "ARN of IAM role for the ecs agent."
  value       = "${aws_iam_role.ecs_service_role.*.arn}"
}
