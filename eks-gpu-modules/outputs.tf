output "network" {
  description = "VPC infra details"
  value = {
    region             = var.aws_region
    vpc_id             = module.vpc.vpc_id
    vpc_cidr           = module.vpc.vpc_cidr
    public_subnet_ids  = [module.main_public1_a.subnet_id, module.main_public2_b.subnet_id, module.main_public3_c.subnet_id, module.main_public4_a.subnet_id, module.main_public5_b.subnet_id, module.main_public6_c.subnet_id]
    private_subnet_ids = [module.main_private1_a.subnet_id, module.main_private2_b.subnet_id, module.main_private3_c.subnet_id, module.main_private4_a.subnet_id, module.main_private5_b.subnet_id, module.main_private6_c.subnet_id]
  }
}

# output "state" {
#   description = "S3 and DynamoDB"
#   value = {
#     s3-bucket-name = aws_s3_bucket.terraform_state.bucket
#     dynamodb-name  = aws_dynamodb_table.terraform_lock.name
#   }
# }

output "cloudwatch_log" {
  value = aws_cloudwatch_log_group.eks_cluster.name
}

output "my_ip_address" {
  value = local.my_ip_cidr
}