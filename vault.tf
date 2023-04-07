

resource "aws_iam_user" "vault_user" {
  name = "vault"
  path = "/system/"
}

data "aws_iam_policy_document" "vault_iam_policy_doc" {
  statement {
    sid = "VaultIAMPolicy"

    actions = [
      "ec2:DescribeInstances",
      "iam:GetInstanceProfile",
      "iam:GetUser",
      "iam:GetRole"
    ]

    resources = [
      aws_iam_role.iam_for_lambda.arn
    ]
  }
}

resource "aws_iam_user_policy" "vault_iam_policy" {
  name = "test"
  user = aws_iam_user.vault_user.name

  policy = data.aws_iam_policy_document.vault_iam_policy_doc.json
}

resource "aws_iam_access_key" "vault_access_key" {
  user    = aws_iam_user.vault_user.name
}

resource "vault_auth_backend" "aws" {
  type = "aws"
}

resource "vault_aws_auth_backend_client" "vault_aws_client" {
  backend    = vault_auth_backend.aws.path
  access_key = aws_iam_access_key.vault_access_key.id
  secret_key = aws_iam_access_key.vault_access_key.secret
}

data "vault_policy_document" "lambda-vault-policy-doc" {
  rule {
    path         = "secret/*"
    capabilities = ["create", "read", "update", "delete", "list"]
    description  = "allow all on secrets"
  }
}

resource "vault_policy" "lambda-vault-policy" {
  name = "lambda-mysecrets"

  policy = data.vault_policy_document.lambda-vault-policy-doc.hcl

}

resource "time_sleep" "wait_15_seconds" {
  create_duration = "15s"
}

resource "vault_aws_auth_backend_role" "lambda_role" {
  depends_on = [vault_auth_backend.aws, aws_iam_role.iam_for_lambda, vault_aws_auth_backend_client.vault_aws_client, time_sleep.wait_15_seconds]
  backend                         = vault_auth_backend.aws.path
  role                            = "vault-lambda-role"
  auth_type                       = "iam"
  bound_iam_principal_arns         = [aws_iam_role.iam_for_lambda.arn]
  token_ttl                       = 60
  token_max_ttl                   = 120
  token_policies                  = ["default", vault_policy.lambda-vault-policy.name]
}