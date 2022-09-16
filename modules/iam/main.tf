resource "aws_iam_role" "external_dns" {
  count = var.is_prod ? 1 : 0

  name               = "external_dns"
  assume_role_policy = templatefile("oidc-policy.json", { OIDC_ARN = var.clsuter_oidc_provider_arn, OIDC_URL = replace(var.cluster_oidc_issuer_url, "https://", "") })
  depends_on         = [var.cluster_oidc_provider]
}

resource "aws_iam_role_policy_attachment" "external_dns_attach" {
  count = var.is_prod ? 1 : 0

  role       = aws_iam_role.external_dns[0].name
  policy_arn = data.terraform_remote_state.global.outputs.iam_policy_external_dns_arn
  depends_on = [aws_iam_role.external_dns]
}


data "terraform_remote_state" "global" {
  backend = "s3"

  config = {
    bucket = "so1s-terraform-remote-state-storage"
    key    = "live/global/terraform.tfstate"
    region = "ap-northeast-2"
  }

}
