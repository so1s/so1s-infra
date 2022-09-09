resource "aws_iam_policy" "alb" {
  name        = "alb-eks"
  description = "use alb in eks"

  policy = file("policies/alb.json")
  tags = {
    Terraform   = "true"
    Environment = "production"
  }
}

resource "aws_iam_policy" "external_dns" {
  name        = "external-dns"
  description = "setting for external dns"

  policy = file("policies/external-dns.json")
  tags = {
    Terraform   = "true"
    Environment = "production"
  }
}
