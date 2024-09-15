data "aws_secretsmanager_secret" "db_credentials" {
  name = "${var.tags.Project}/db_credentials"
}

data "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = data.aws_secretsmanager_secret.db_credentials.id
}

locals {
  db_creds = jsondecode(data.aws_secretsmanager_secret_version.db_credentials.secret_string)
}

resource "aws_db_instance" "main" {
  identifier           = var.db_name
  engine               = var.db_engine
  engine_version       = var.db_engine_version
  instance_class       = var.db_instance_class
  allocated_storage    = var.db_storage
  storage_type         = var.db_storage_type
  multi_az             = true
  db_name              = var.db_name
  username             = local.db_creds.username
  password             = local.db_creds.password
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  skip_final_snapshot  = true
  tags                 = var.tags
}

resource "aws_ssm_parameter" "db_name" {
  name  = "/${var.tags.Project}/db_name"
  type  = "String"
  value = aws_db_instance.main.db_name
}

resource "aws_ssm_parameter" "db_endpoint" {
  name  = "/${var.tags.Project}/db_endpoint"
  type  = "String"
  value = aws_db_instance.main.endpoint
}

resource "null_resource" "db_init" {
  depends_on = [aws_db_instance.main, aws_lambda_function.db_init]

  provisioner "local-exec" {
    command = <<EOF
       aws lambda invoke --function-name ${aws_lambda_function.db_init.function_name} --region ${var.aws_region} response.json & type response.json
    EOF
  }
}

output "rds_endpoint" {
  value = aws_db_instance.main.endpoint
}

output "db_name" {
  value = aws_db_instance.main.db_name
}