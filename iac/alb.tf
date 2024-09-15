# Define Application Load Balancer
resource "aws_lb" "app_lb" {
  name               = "${var.tags.Project}-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id]
}

# Define IAM role for EC2 instances
resource "aws_iam_role" "ec2_role" {
  name = "${var.tags.Project}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "rds_access_policy" {
  name = "${var.tags.Project}-rds-access-policy"
  role = aws_iam_role.ec2_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds-db:connect",
        ]
        Resource = "arn:aws:rds:${var.aws_region}:${var.account_id}:db:${var.db_name}"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "secrets_manager_policy" {
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
  role       = aws_iam_role.ec2_role.name
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.tags.Project}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# Define Target Group for ALB
resource "aws_lb_target_group" "app_tg" {
  name     = "${var.tags.Project}-tg"
  port     = var.instance_inbound_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

# Define Listener for ALB
resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = var.ingress_alb_port
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# Define Launch Template for ASG
resource "aws_launch_template" "app_lt" {
  name_prefix   = "${var.tags.Project}-lt"
  image_id      = var.instance_ami # replace with an Ubuntu AMI ID
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.instance_sg.id]
  }

  user_data = base64encode(<<-EOF
                DB_CREDS=$(aws secretsmanager get-secret-value --secret-id "${var.tags.Project}/db_credentials" --query SecretString --output text)
                DB_USERNAME=$(echo $DB_CREDS | jq -r .username)
                DB_PASSWORD=$(echo $DB_CREDS | jq -r .password)
                DB_NAME=${var.db_name}
                DB_ENDPOINT=${aws_db_instance.main.endpoint}
                sudo systemctl restart spring-petclinic       
                EOF
    )
}

# Define Auto Scaling Group
resource "aws_autoscaling_group" "app_asg" {
  desired_capacity     = var.desired_capacity
  max_size             = var.max_size
  min_size             = var.min_size
  vpc_zone_identifier  = [aws_subnet.private_a.id,
  aws_subnet.private_b.id
  ]

  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.app_tg.arn]

  tag {
      key = "Name"
      value = "${var.tags.Project}-asg"
      propagate_at_launch = true
    }
  
  depends_on = [null_resource.db_init]
}

resource "aws_autoscaling_policy" "scale_out_policy" {
  name                   = "scale-out-policy"
  scaling_adjustment      = 1
  adjustment_type         = "ChangeInCapacity"
  cooldown                = 300
  autoscaling_group_name  = aws_autoscaling_group.app_asg.name
}

resource "aws_autoscaling_policy" "scale_in_policy" {
  name                   = "scale-in"
  scaling_adjustment      = -1
  adjustment_type         = "ChangeInCapacity"
  cooldown                = 300
  autoscaling_group_name  = aws_autoscaling_group.app_asg.name
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This alarm triggers when CPU utilization is above 70%"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_asg.name
  }
  alarm_actions = [aws_autoscaling_policy.scale_out_policy.arn]
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "30"
  alarm_description   = "This alarm triggers when CPU utilization is below 30%"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_asg.name
  }
  alarm_actions = [aws_autoscaling_policy.scale_in_policy.arn]
}