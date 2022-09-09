output "iam_policy_alb_arn" {
  value = aws_iam_policy.alb.arn
}

output "iam_policy_external_dns_arn" {
  value = aws_iam_policy.external_dns.arn
}

