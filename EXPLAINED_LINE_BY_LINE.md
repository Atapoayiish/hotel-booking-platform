# LINE BY LINE
VPC /16: 65k IPs. 2 AZs: AZ dies, other serves. NAT single: $32 learning.
RDS db.t3.micro: Free Tier only size. Backup 0: Free Tier only. Replica OFF: replica needs backup>0, Free Tier allows 0 - conflict, so OFF for learning.
Redis TTL 60s: fresh + fast. HPA 65%: headroom. ALB /health: remove sick pod. S3 versioning+block: locked+recover. OIDC: temp pass not master key.
