resource "aws_iam_policy" "alb" {
  name        = "alb-eks"
  description = "use alb in eks"

  policy = file("alb.json")
  tags = {
    Terraform   = "true"
    Environment = "production"
  }
}

resource "aws_iam_policy" "external_dns" {
  name        = "external-dns"
  description = "setting for external dns"

  policy = file("external-dns.json")
  tags = {
    Terraform   = "true"
    Environment = "production"
  }
}

resource "aws_iam_role" "grafana_cloudwatch" {
  name = "grafana-cloudwatch-datasource"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:DescribeInstances",
          "tag:GetResources",
          "logs:DescribeLogGroups",
          "cloudwatch:GetInsightRuleReport",
          "cloudwatch:GetMetricData",
          "ec2:DescribeTags",
          "ec2:DescribeRegions",
          "logs:StartQuery",
          "logs:StopQuery",
          "logs:CreateLogGroup",
          "cloudwatch:ListMetrics",
          "cloudwatch:DescribeAlarmHistory",
          "logs:GetQueryResults",
          "cloudwatch:DescribeAlarmsForMetric",
          "logs:GetLogEvents",
          "cloudwatch:DescribeAlarms",
          "logs:GetLogGroupFields"
        ]
        Effect   = "Allow"
        Sid      = "VisualEditor0"
        Resource = "*"
      }
    ]
  })

  tags = {
    Terraform   = "true"
    Environment = "production"
  }
}
