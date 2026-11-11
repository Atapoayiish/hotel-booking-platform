# LIVE GUIDE
PHASE 0: AWS account, IAM hotel-admin, aws configure eu-west-1
PHASE 1: aws s3 mb s3://hotel-tf-state-sa-2026 --region eu-west-1 + versioning
PHASE 3: cd 01-network terraform init/plan/apply, then 02-data same, then 03-compute same
PHASE 4: aws eks update-kubeconfig --name hotel-eks --region eu-west-1, kubectl create namespace production, create secret hotel-secrets (db_replica_host = same as db_host in Free Tier)
PHASE 5: kubectl apply k8s/
PHASE 6: Docker build/push ECR, kubectl set image
PHASE 7: GitHub OIDC role, edit deploy.yml ARN, git push
PHASE 8: curl CloudFront domain
PHASE 9: destroy 03,02,01
