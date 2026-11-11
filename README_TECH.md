# CTO
Client -> CloudFront -> ALB -> EKS -> Redis cache-aside 60s + RDS Primary (reads+writes in Free Tier learning) -> S3.
VPC /16, 2 AZs. EKS nodes t3.micro Free Tier (production: t3.medium). RDS MySQL 8.0 db.t3.micro gp3 20GB backup 0 Free Tier. Redis cache.t3.micro.
Replica: DISABLED for Free Tier. Reason: AWS requires backup_retention >0 to create a replica. Free Tier max is 0. Cannot have both. Production: backup 7 + replica db.t3.micro.
Cost learning: NAT ~$32 + small EC2/RDS/Redis, destroy after demo.
