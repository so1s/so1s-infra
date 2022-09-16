output "external_dns_role_arn" {
  description = "External DNS ARN for external-dns chart values.yaml"
  value       = var.is_prod ? aws_iam_role.external_dns[0].arn : null
}
