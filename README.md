# AWS - Force Free Tier

This tool instantly reacts to events in your AWS environment to keep you from spending money. 
The main drivers behind this tool are [EventBridge](https://aws.amazon.com/eventbridge/) and [Lambda](https://aws.amazon.com/lambda/).
AWS Resources you try to create will be instantly deleted if they would have taken you out of Free Tier.

[AWS Free Tier Reference](https://aws.amazon.com/free)

### Setup Steps
1. Install & Configure the [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) if you haven't already.
    - [Mac Installation](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-mac.html#cliv2-mac-install-gui)
    - [Windows Installation](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-windows.html#cliv2-windows-install)
2. Install & Configure [Terraform](https://www.terraform.io/downloads.html) if you haven't already.
3. Run these commands in this directory:
```
terraform init
terraform apply
```

### Uninstall Steps
1. Run this command in this directory to remove the tool from your AWS environment:
```
terraform destroy
```

# Services

## DynamoDB
- [x] 25 provisioned Write Capacity Units (WCU)
- [x] 25 provisioned Read Capacity Units (RCU)

## EBS
- [x] 30GB total storage for General Purpose (SSD) or Magnetic
- [x] 1GB of snapshot storage

## EC2
- [x] Restrict instance types to `t2.micro` or `t3.micro` (depending on region)
- [ ] 750 hours/month of EC2 compute usage

## ECR
- [x] 500MB of storage

## ElastiCache
- [ ] Restrict instance types to `cache.t2.micro` or `cache.t3.micro`
- [ ] 750 hours/month of compute usage

## Elasticsearch
- [ ] Restrict instance types to `t2.small.elasticsearch` or `t3.small.elasticsearch`
- [ ] Restrict clusters to single-AZ
- [ ] 750 hours/month of compute usage

## GameLift
- [ ] Restrict instance types to `c3.large`, `c4.large` or `c5.large` (depending on region)
- [ ] 125 hours/month of compute usage

## RDS
- [x] Restrict instance types to `db.t2.micro`
- [x] Restrict DB engines to MySQL, PostgreSQL, MariaDB, Oracle BYOL, or SQL Server
- [ ] 750 hours/month of RDS database usage
- [x] 20GB of General Purpose (SSD) storage
- [x] 20GB of DB backups and snapshots
