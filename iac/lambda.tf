data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda_function.zip"
  source_dir  = "${path.module}/lambda"
  depends_on = [null_resource.lambda_dependencies]
}

resource "aws_lambda_function" "db_init" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.tags.Project}-db-init"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_initialization_db_function.lambda_handler"
  runtime          = "python3.8"
  timeout          = 900
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      DB_SECRET_ARN = data.aws_secretsmanager_secret.db_credentials.arn
      DB_NAME       = var.db_name
      DB_ENDPOINT   = aws_db_instance.main.endpoint
    }
  }

  vpc_config {
    subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  depends_on = [ aws_vpc_endpoint.secretsmanager ]
}

resource "null_resource" "lambda_dependencies" {
  triggers = {
    dependencies_versions = filemd5("${path.module}/lambda/requirements.txt")
    source_versions = filemd5("${path.module}/lambda/lambda_initialization_db_function.py")
  }

  provisioner "local-exec" {
    command = <<EOF
      pip install --target=${path.module}/lambda -r ${path.module}/lambda/requirements.txt
    cp ${path.module}/lambda/sql/*.sql ${path.module}/lambda/
    EOF
  }
}

resource "aws_iam_role" "lambda_role" {
  name = "${var.tags.Project}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  role       = aws_iam_role.lambda_role.name
}

resource "aws_iam_role_policy" "secrets_manager_policy" {
  name = "${var.tags.Project}-secrets-manager-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
        ]
        Resource = data.aws_secretsmanager_secret.db_credentials.arn
      }
    ]
  })
}

