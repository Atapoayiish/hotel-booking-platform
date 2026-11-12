# Hotel Booking Platform — Airbnb Clone | Project 1: BUILD

**LIVE Demo:** http://a4025e9950d1547729c710695479508a-1422354246.eu-west-1.elb.amazonaws.com/hotels
**GitHub:** https://github.com/Atapoayiish/hotel-booking-platform
**Stack:** CloudFront (disabled for Free Tier) -> ALB -> EKS -> RDS + Redis -> S3
**Region:** eu-west-1 (Ireland) | **Cluster:** hotel-eks

## What it does
Airbnb-style hotel booking API with 5 hotels: Accra, Kumasi, Cape Coast, Takoradi, Tamale.
- `GET /health` -> {"status":"ok"}
- `GET /hotels` -> All hotels (first call: rds-or-memory, second call: redis-cache)
- `GET /hotels?city=Accra` -> Filter by city
- `GET /hotels/1` -> One hotel

## Screenshots
![Hotels LIVE](images/hotels-live.png)
![Pods Running](images/pods-running.png)
![GitHub Actions Green](images/github-actions-green.png)

## Architecture
Client -> ALB (LoadBalancer) -> EKS (hotel-eks, t3.micro nodes) -> RDS Primary (MySQL 8.0, db.t3.micro) + Redis (cache.t3.micro, 60s TTL) -> S3 (hotel-images-sa-2026)
CI/CD: GitHub Actions with OIDC -> ECR -> EKS

## How to deploy
1. `terraform apply` in 01-network, 02-data, 03-compute
2. `aws eks update-kubeconfig --name hotel-eks --region eu-west-1`
3. `kubectl create secret generic hotel-secrets --namespace production --from-literal=db_host=...`
4. `kubectl apply -f k8s/`
5. `git push` -> 【entity-GitHub Actions¦canonical_name=GitHub】 builds Docker, pushes to ECR, deploys to EKS

## Real problems fixed (not tutorial)
- Free Tier: backup_retention 7 -> 0, db.t3.small -> db.t3.micro
- Replica vs Backup conflict: Replica needs backup >0, Free Tier allows 0, so Replica disabled for learning, Primary handles reads+writes
- EKS 1.29 unsupported -> 1.32
- CloudFront blocked for new accounts -> Disabled, used ALB directly
- GitHub OIDC July 2026 immutable subject claims: subject now uses numeric owner/repo IDs, not names, so Trust Policy must use wildcard
- ECR 401: Missing AmazonEC2ContainerRegistryPowerUser on GitHub role
- EKS DescribeCluster denied: Added custom policy eks:DescribeCluster
- ImagePullBackOff: deployment.yaml had placeholder hotel-app:latest, fixed to ECR URL
- Progress deadline: t3.micro cannot fit 2 pods, scaled to 1 replica

## Cost (learning)
NAT ~$32/mo + EKS nodes + RDS + Redis. Destroy after demo: terraform destroy in 03-compute, 02-data, 01-network.
