output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "The ID of the public subnet"
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "The ID of the private subnet"
  value       = aws_subnet.private.id
}

output "autoscaling_group_name" {
  description = "The name of the Auto Scaling Group"
  value       = aws_autoscaling_group.asg.name
}

output "eip_alloc_id" {
  value = var.eip_alloc_id
}

output "nat_gateway_id" {
  value = aws_nat_gateway.nat.id
}
