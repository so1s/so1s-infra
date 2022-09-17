output "external_dns_role_arn" {
  description = "External DNS ARN for external-dns chart values.yaml"
  value       = aws_iam_role.external_dns.arn
}
