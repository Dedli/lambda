
// create new iam user which is used by vault to evaluate iam role arns for aws authentication
resource "aws_iam_user" "vault_user" {
  name = "vault"
  path = "/system/"
}

// vault needs to check the given role arns so it needs to be allowed to call the following actions
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

// creat policy from previously created policy document
resource "aws_iam_user_policy" "vault_iam_policy" {
  name = "test"
  user = aws_iam_user.vault_user.name

  policy = data.aws_iam_policy_document.vault_iam_policy_doc.json
}

// create access key to put it to aws authentication in vault
resource "aws_iam_access_key" "vault_access_key" {
  user    = aws_iam_user.vault_user.name
}

// enable aws authentication in vault
resource "vault_auth_backend" "aws" {
  type = "aws"
}

// vault also needs access to your aws account to check given iam role arns inside aws authentication method
resource "vault_aws_auth_backend_client" "vault_aws_client" {
  backend    = vault_auth_backend.aws.path
  access_key = aws_iam_access_key.vault_access_key.id
  secret_key = aws_iam_access_key.vault_access_key.secret
}

// policy document which allows all operations on the secret backend (secret backend is default for Key-Value)
data "vault_policy_document" "lambda-vault-policy-doc" {
  rule {
    path         = "secret/*"
    capabilities = ["create", "read", "update", "delete", "list"]
    description  = "allow all on secrets"
  }
}

// policy in vault to which will be attached to the aws authentication role and assigned to the lambda function.
resource "vault_policy" "lambda-vault-policy" {
  name = "lambda-mysecrets"

  policy = data.vault_policy_document.lambda-vault-policy-doc.hcl

}


// sleep timer because previously created access keys might not be valid before which leads otherwise to an error.
resource "time_sleep" "wait_15_seconds" {
  create_duration = "15s"
}

// aws authentictaion role in vault used by lambda to authenticate against vault
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