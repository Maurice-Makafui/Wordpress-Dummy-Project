output "endpoint" {
  description = "RDS instance endpoint (host:port)"
  value       = aws_db_instance.this.endpoint
}

output "identifier" {
  description = "RDS instance identifier"
  value       = aws_db_instance.this.identifier
}
