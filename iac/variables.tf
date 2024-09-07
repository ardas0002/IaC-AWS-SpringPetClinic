# AWS Region
variable "aws_region" {
  description = "The AWS region where the infrastructure will be deployed"
  type        = string
  default     = "us-east-1"
}

# VPC CIDR Block
variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zone_a" {
    description = "The AZ A"
    type        = string
    default     = "us-east-1a"
}

variable "availability_zone_b" {
    description = "The AZ B"
    type = string
    default = "us-east-1b"
}

# Public Subnet CIDR Blocks
variable "public_subnet_a_cidr" {
  description = "The CIDR block for the public subnet in Availability Zone 1"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_b_cidr" {
  description = "The CIDR block for the public subnet in Availability Zone 2"
  type        = string
  default     = "10.0.3.0/24"
}

# Private Subnet CIDR Blocks
variable "private_subnet_a_cidr" {
  description = "The CIDR block for the private subnet in Availability Zone 1"
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_subnet_b_cidr" {
  description = "The CIDR block for the private subnet in Availability Zone 2"
  type        = string
  default     = "10.0.4.0/24"
}

variable "private_db_subnet_a_cidr" {
  description = "The CIDR block for the private db subnet in Availability Zone 1"
  type        = string
  default     = "10.0.5.0/24"
}

variable "private_db_subnet_b_cidr" {
  description = "The CIDR block for the private db subnet in Availability Zone 2"
  type        = string
  default     = "10.0.6.0/24"
}

variable "instance_inbound_port" {
  description = "The port of instance inbound connection"
  type = number
  default = 8080
}

# Instance AMI
variable "instance_ami" {
  description = "The Amazon Machine Image (AMI) ID for EC2 instances"
  type        = string
  default     = "ami-03b1721d5d0ea0803" 
}

# Instance Type
variable "instance_type" {
  description = "The EC2 instance type for the auto-scaling group"
  type        = string
  default     = "t2.micro"
}

# Desired Capacity for ASG
variable "desired_capacity" {
  description = "The desired number of instances in the auto-scaling group"
  type        = number
  default     = 2
}

# Minimum Size for ASG
variable "min_size" {
  description = "The minimum number of instances in the auto-scaling group"
  type        = number
  default     = 2
}

# Maximum Size for ASG
variable "max_size" {
  description = "The maximum number of instances in the auto-scaling group"
  type        = number
  default     = 4
}

# Tags
variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default = {
    Project     = "springpetclinic"
  }
}

variable "db_name" {
  description = "Name of the database"
  default     = "springpetclinicdb"
}

variable "db_instance_class" {
  description = "RDS instance class"
  default     = "db.t3.micro"
}

variable "db_engine" {
  description = "Database engine"
  default     = "mysql"
}

variable "db_engine_version" {
  description = "Database engine version"
  default     = "8.0.33"
}

variable "db_storage_type" {
  description = "Database storage type"
  default     = "gp2"
}

variable "db_storage" {
  description = "Database storage"
  default     = 10
}

variable "ingress_alb_port" {
  description = "The port of ingress alb connection"
  type = number
  default = 80
}

variable "database_port" {
  description = "The port of database connection"
  type = number
  default = 3306
}