# Security Groups
resource "aws_security_group" "alb_sg" {
  name        = "${var.tags.Project}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.main.id
  tags        = var.tags
}

resource "aws_security_group" "instance_sg" {
  name        = "${var.tags.Project}-instance-sg"
  description = "Security group for EC2 instances in ASG"
  vpc_id      = aws_vpc.main.id
  tags        = var.tags
}

resource "aws_security_group" "db_sg" {
  name        = "${var.tags.Project}-db-sg"
  description = "Security group for RDS database"
  vpc_id      = aws_vpc.main.id
  tags        = var.tags
}

resource "aws_security_group" "lambda_sg" {
  name        = "${var.tags.Project}-lambda-sg"
  description = "Security group for Lambda"
  vpc_id      = aws_vpc.main.id
  tags        = var.tags
}

resource "aws_security_group" "secretsmanager_endpoint_sg" {
  name        = "${var.tags.Project}-secretsmanager-endpoint-sg"
  description = "Security group for Secrets Manager VPC endpoint"
  vpc_id      = aws_vpc.main.id
  tags        = var.tags
}

# Security Group Rules for ALB
resource "aws_security_group_rule" "alb_ingress_http" {
  type              = "ingress"
  from_port         = var.ingress_alb_port
  to_port           = var.ingress_alb_port
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb_sg.id
}

resource "aws_security_group_rule" "alb_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb_sg.id
}

# Security Group Rules for EC2 Instances
resource "aws_security_group_rule" "instance_ingress_from_alb" {
  type                     = "ingress"
  from_port                = var.instance_inbound_port
  to_port                  = var.instance_inbound_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb_sg.id
  security_group_id        = aws_security_group.instance_sg.id
}

resource "aws_security_group_rule" "instance_egress_to_db" {
  type                     = "egress"
  from_port                = var.database_port
  to_port                  = var.database_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.db_sg.id
  security_group_id        = aws_security_group.instance_sg.id
}

# Security Group Rules for RDS
resource "aws_security_group_rule" "db_ingress_from_instance" {
  type                     = "ingress"
  from_port                = var.database_port
  to_port                  = var.database_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.instance_sg.id
  security_group_id        = aws_security_group.db_sg.id
}

resource "aws_security_group_rule" "db_ingress_from_lambda" {
  type                     = "ingress"
  from_port                = var.database_port
  to_port                  = var.database_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.lambda_sg.id
  security_group_id        = aws_security_group.db_sg.id
}

resource "aws_security_group_rule" "lambda_egress_to_db" {
  type                     = "egress"
  from_port                = var.database_port
  to_port                  = var.database_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.db_sg.id
  security_group_id        = aws_security_group.lambda_sg.id
}

resource "aws_security_group_rule" "lambda_to_secretsmanager" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.lambda_sg.id
  source_security_group_id = aws_security_group.secretsmanager_endpoint_sg.id
}

resource "aws_security_group_rule" "secretsmanager_from_lambda" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.secretsmanager_endpoint_sg.id
  source_security_group_id = aws_security_group.lambda_sg.id
}