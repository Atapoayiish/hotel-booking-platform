# Hotel Booking Platform - Airbnb Clone | Project 1: BUILD
Stack: CloudFront -> ALB -> EKS -> RDS Primary + Redis -> S3
Region: eu-west-1 | State bucket: hotel-tf-state-sa-2026 | Cluster: hotel-eks
FREE TIER NOTE: This version is tuned for AWS Free Tier. RDS is db.t3.micro, backup retention 0, NO read replica (replica requires backups >0, Free Tier allows 0 - they fight each other). In production, set backup 7 + add replica back. See 02-data/main.tf comments.
Order: 01-network -> 02-data -> 03-compute -> kubectl + secrets -> k8s -> Docker/ECR -> GitHub pipeline -> Test LIVE -> Destroy
See LIVE_DEPLOYMENT_GUIDE.md
