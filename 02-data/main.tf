data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "hotel-tf-state-sa-2026"
    key    = "01-network/terraform.tfstate"
    region = "eu-west-1"
  }
}
resource "aws_security_group" "data" {
  name   = "hotel-data-sg"
  vpc_id = data.terraform_remote_state.network.outputs.vpc_id
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "MySQL from VPC"
  }
  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "Redis from VPC"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "hotel-data-sg"
  }
}
resource "aws_db_subnet_group" "main" {
  name       = "hotel-db-subnet-group"
  subnet_ids = data.terraform_remote_state.network.outputs.private_subnets
  tags = {
    Name = "hotel-db-subnet-group"
  }
}
resource "aws_db_instance" "primary" {
  identifier               = "hotel-db-primary"
  engine                   = "mysql"
  engine_version           = "8.0"
  instance_class           = "db.t3.micro"
  allocated_storage        = 20
  storage_type             = "gp3"
  db_name                  = var.db_name
  username                 = var.db_username
  password                 = var.db_password
  db_subnet_group_name     = aws_db_subnet_group.main.name
  vpc_security_group_ids   = [aws_security_group.data.id]
  backup_retention_period  = 0
  delete_automated_backups = true
  deletion_protection      = false
  skip_final_snapshot      = true
  publicly_accessible      = false
  tags = {
    Name = "hotel-db-primary"
  }
}
# FREE TIER NOTE: Read Replica is DISABLED on purpose.
# AWS rule: A replica can only be created if Primary has backup_retention_period > 0.
# Free Tier rule: backup_retention_period max is 0.
# Those two rules fight each other, so you CANNOT have both on Free Tier.
# Fix for learning: No replica, Primary handles reads + writes.
# Fix for production (paid account): Set backup_retention_period = 7 on Primary, then uncomment the replica block below.
# resource "aws_db_instance" "replica" {
#   identifier = "hotel-db-replica"
#   replicate_source_db = aws_db_instance.primary.identifier
#   instance_class = "db.t3.micro"
#   publicly_accessible = false
#   skip_final_snapshot = true
#   tags = {
#     Name = "hotel-db-replica"
#   }
# }
resource "aws_elasticache_subnet_group" "main" {
  name       = "hotel-redis-subnet-group"
  subnet_ids = data.terraform_remote_state.network.outputs.private_subnets
}
resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "hotel-redis"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  subnet_group_name    = aws_elasticache_subnet_group.main.name
  security_group_ids   = [aws_security_group.data.id]
  tags = {
    Name = "hotel-redis"
  }
}
output "rds_primary_endpoint" {
  value = aws_db_instance.primary.address
}
output "rds_replica_endpoint" {
  value = aws_db_instance.primary.address
}
output "redis_endpoint" {
  value = aws_elasticache_cluster.redis.cache_nodes[0].address
}
output "data_sg_id" {
  value = aws_security_group.data.id
}
