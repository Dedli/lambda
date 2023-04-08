// lambda needs to be able to make an sts:AssumeRole to a given iam role
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

// create iam role from previous created policy document
resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

// install all dependencies from requirements.txt, this must be done because all dependencies needs to be inside the zip file which is uplodaded to the lambda
resource "null_resource" "install_dependencies" {
  provisioner "local-exec" {
    command = "pip install -r ${path.module}/src/requirements.txt -t ${path.module}/src/"
  }

  triggers = {
    dependencies_versions = filemd5("${path.module}/src/requirements.txt")
    source_versions = filemd5("${path.module}/src/vault.py")
  }
}

// put everything into a zip file
data "archive_file" "lambda_zip" {
  depends_on = [null_resource.install_dependencies]
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/zip/vault_lambda.zip"
}

# This is to optionally manage the CloudWatch Log Group for the Lambda Function.
# If skipping this resource configuration, also add "logs:CreateLogGroup" to the IAM policy below.
resource "aws_cloudwatch_log_group" "example" {
  name              = "/aws/lambda/vault_lambda"
  retention_in_days = 14
}

# See also the following AWS managed policy: AWSLambdaBasicExecutionRole
# give the Lambda the rights to write logs
data "aws_iam_policy_document" "lambda_logging" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"
  policy      = data.aws_iam_policy_document.lambda_logging.json
}

// attache log permissions to previously created iam role
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

// create the lambda function using the zip file created before
resource "aws_lambda_function" "demo_lambda" {
  depends_on = [vault_auth_backend.aws, aws_iam_role.iam_for_lambda]
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  role             = aws_iam_role.iam_for_lambda.arn
  function_name    = "vault_lambda"
  handler          = "vault.lambda_handler"
  runtime          = "python3.9"
  environment {
    variables = {
      VAULT_ADDR = var.vault_addr
      VAULT_SECRET_TO_READ = var.secret_to_read
    }
  }
}