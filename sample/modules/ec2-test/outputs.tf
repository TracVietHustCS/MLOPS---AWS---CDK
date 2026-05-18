output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.test.id
}

output "private_ip" {
  description = "Private IP of the test instance"
  value       = aws_instance.test.private_ip
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.test_instance.id
}

output "ssm_connect_command" {
  description = "Command to connect via SSM Session Manager"
  value       = "aws ssm start-session --target ${aws_instance.test.id} --region ${data.aws_region.current.id}"
}

output "view_results_command" {
  description = "Command to view test results after connecting"
  value       = "cat /home/ec2-user/vpc-endpoint-results.txt"
}
