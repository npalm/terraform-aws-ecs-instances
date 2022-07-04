data "aws_iam_policy_document" "ecs_service_role" {
  #count = "${var.create_ecs_service_role ? 1 : 0}"

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_service_role" {
  #count = "${var.create_ecs_service_role ? 1 : 0}"

  name               = "${var.environment}-ecs-service-role"
  assume_role_policy = "${data.aws_iam_policy_document.ecs_service_role.json}"
}

data "template_file" "ecs_service_role_policy" {
  #count = "${var.create_ecs_service_role ? 1 : 0}"

  template = "${file("${path.module}/policies/service-role-policy.json")}"
}

resource "aws_iam_role_policy" "service_role_policy" {
  #count = "${var.create_ecs_service_role ? 1 : 0}"

  name   = "${var.environment}-ecs-service-role-policy"
  role   = "${aws_iam_role.ecs_service_role.name}"
  policy = "${data.template_file.ecs_service_role_policy.rendered}"
}
