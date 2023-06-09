output "instance_id" {
  value = aws_instance.ec2_instance.id
}

output "s3_bucket" {
  value = module.s3.s3_bucket_id
}
