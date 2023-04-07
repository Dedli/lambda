data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "null_resource" "install_dependencies" {
  provisioner "local-exec" {
    command = "pip install -r ${path.module}/src/requirements.txt -t ${path.module}/src/"
  }

  triggers = {
    dependencies_versions = filemd5("${path.module}/src/requirements.txt")
    source_versions = filemd5("${path.module}/src/vault.py")
  }
}

data "archive_file" "lambda_zip" {
  depends_on = [null_resource.install_dependencies]
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/zip/vault_lambda.zip"
}

resource "aws_lambda_function" "demo_lambda" {
  depends_on = [vault_auth_backend.aws, aws_iam_role.iam_for_lambda]
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  role             = aws_iam_role.iam_for_lambda.arn
  function_name    = "vault_lambda"
  handler          = "vault.lambda_handler"
  runtime          = "python3.8"
  environment {
    variables = {
      VAULT_ADDR = var.vault_addr
    }
  }
}