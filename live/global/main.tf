resource "aws_iam_policy" "alb" {
  name        = "alb-eks"
  description = "use alb in eks"

  policy = file("alb.json")
  tags = {
    Terraform   = "true"
    Environment = "production"
  }
}
