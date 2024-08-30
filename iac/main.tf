provider "aws" {
  region = "us-east-2"
}

# Define VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# Define public subnet for ALB
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

# Define private subnet for EC2 instances
resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
}

# Define Internet Gateway for public access
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

# Define Route Table for public subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

# Associate Route Table with Public Subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security group for ALB allowing HTTP access
resource "aws_security_group" "alb_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security group for EC2 instances in ASG
resource "aws_security_group" "instance_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # Egress rules: Block all outgoing traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = []
  }
}

# Define Application Load Balancer
resource "aws_lb" "app_lb" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public.id]
}

# Define Target Group for ALB
resource "aws_lb_target_group" "app_tg" {
  name     = "app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

# Define Listener for ALB
resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# Define Launch Template for ASG
resource "aws_launch_template" "app_lt" {
  name_prefix   = "app-"
  image_id      = "ami-12345678" # replace with an Ubuntu AMI ID
  instance_type = "t2.micro"

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.instance_sg.id]
  }

  user_data = <<-EOF
              #!/bin/bash
              # Update packages and install Java 17 and Maven
              apt-get update -y
              apt-get install -y openjdk-17-jdk maven git

              # Clone the Spring Petclinic repository
              git clone https://github.com/spring-projects/spring-petclinic.git /home/ubuntu/spring-petclinic

              # Build the application
              cd /home/ubuntu/spring-petclinic
              ./mvnw package

              # Run the application
              java -jar target/*.jar
              EOF
}

# Define Auto Scaling Group
resource "aws_autoscaling_group" "app_asg" {
  desired_capacity     = 1
  max_size             = 2
  min_size             = 1
  vpc_zone_identifier  = [aws_subnet.private.id]

  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.app_tg.arn]
}

# Define IAM Role for EC2 instances to access necessary AWS services
resource "aws_iam_role" "ecs_instance_role" {
  name               = "ecs-instance-role"
  assume_role_policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOF
}

