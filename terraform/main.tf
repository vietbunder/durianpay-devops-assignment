# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
}

# Internet Gateway for Public Subnet
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                   = aws_vpc.main.id
  cidr_block               = var.public_subnet_cidr
  map_public_ip_on_launch  = true
}

# Route Table for Public Subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
}

# Route for Internet access
resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Associate Public Subnet with Public Route Table
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Create NAT Gateway using the existing EIP (Elastic IP)
resource "aws_nat_gateway" "nat" {
  allocation_id = var.eip_alloc_id
  subnet_id     = aws_subnet.public.id  # Public subnet, not private subnet
  depends_on    = [aws_internet_gateway.igw]

  tags = {
    Name = "NAT Gateway"
  }
}

# Private Subnet
resource "aws_subnet" "private" {
  vpc_id                   = aws_vpc.main.id
  cidr_block               = var.private_subnet_cidr
  map_public_ip_on_launch  = false
}

# Route Table for Private Subnet
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
}

# Route for the Private Subnet that routes traffic through the NAT Gateway
resource "aws_route" "private_nat_gateway" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

# Associate Private Subnet with Private Route Table
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# Security Group for EC2 Instances
resource "aws_security_group" "ec2_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
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

# Launch Template for Auto Scaling Group
resource "aws_launch_template" "ec2" {
  name          = "asg-launch"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  monitoring {
    enabled = true
  }

  network_interfaces {
    security_groups = [aws_security_group.ec2_sg.id]
    associate_public_ip_address = false
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group Definition
resource "aws_autoscaling_group" "asg" {
  vpc_zone_identifier = [aws_subnet.private.id]
  max_size            = 5
  min_size            = 2
  desired_capacity    = 2
  launch_template {
    id      = aws_launch_template.ec2.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "ASG Instance"
    propagate_at_launch = true
  }

  health_check_type          = "EC2"
  health_check_grace_period  = 300
  force_delete               = true
}

# Scaling Policy for Scaling Up (CPU >= 45%)
resource "aws_autoscaling_policy" "scale_up" {
  name                      = "scale_up_policy"
  policy_type               = "TargetTrackingScaling"  # Use TargetTrackingScaling
  metric_aggregation_type   = "Average"
  autoscaling_group_name     = aws_autoscaling_group.asg.name

  target_tracking_configuration {
    target_value = 45
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
  }
}

# Scaling Policy for Scaling Down (CPU <= 30%)
resource "aws_autoscaling_policy" "scale_down" {
  name                      = "scale_down_policy"
  policy_type               = "TargetTrackingScaling"  # Use TargetTrackingScaling
  metric_aggregation_type   = "Average"
  autoscaling_group_name     = aws_autoscaling_group.asg.name

  target_tracking_configuration {
    target_value = 30
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
  }
}

# CloudWatch Alarm for High CPU Utilization (>= 45%)
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "HighCPUUtilization"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 45
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]
  actions_enabled     = true

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }
}

# CloudWatch Alarm for Low CPU Utilization (<= 30%)
resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "LowCPUUtilization"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 30
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }
}

# CloudWatch Alarm for Status Check Failure
resource "aws_cloudwatch_metric_alarm" "status_check_failed" {
  alarm_name          = "StatusCheckFailed"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 1
  alarm_actions       = []

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }
}

# CloudWatch Alarm for High Memory Usage (using CloudWatch Agent)
resource "aws_cloudwatch_metric_alarm" "memory_high" {
  alarm_name          = "HighMemoryUtilization"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = 300
  statistic           = "Average"
  threshold           = 85
  alarm_actions       = []

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }
}

# CloudWatch Alarm for High Network In (>= 1 GB)
resource "aws_cloudwatch_metric_alarm" "network_in_high" {
  alarm_name          = "HighNetworkIn"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "NetworkIn"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 1073741824  # 1 GB in bytes
  alarm_actions       = []

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }
}
