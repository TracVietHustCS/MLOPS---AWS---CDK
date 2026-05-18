data "aws_region" "current" {}

resource "aws_iam_role" "this" {
  name                 = var.role_name
  assume_role_policy   = var.assume_role_policy
  permissions_boundary = var.permissions_boundary

  tags = merge(
    {
      Name = var.role_name
    },
    var.tags
  )
}

resource "aws_iam_role_policy" "inline" {
  for_each = var.inline_policies

  name   = each.key
  role   = aws_iam_role.this.id
  policy = each.value
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each = toset(var.managed_policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = each.value
}

resource "aws_iam_instance_profile" "this" {
  count = var.create_instance_profile ? 1 : 0
  name  = "${var.role_name}-profile"
  role  = aws_iam_role.this.name

  tags = merge(
    {
      Name = "${var.role_name}-profile"
    },
    var.tags
  )
}
