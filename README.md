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

## EC2
- [x] Restrict instance types to t2.micro
- [x] Restrict instance types to t3.micro in select regions
- [ ] 750 hours/month of EC2 compute usage

## EBS
- [x] 30GB total storage for General Purpose (SSD) or Magnetic
- [ ] 1GB of snapshot storage

## RDS
- [x] Restrict instance types to db.t2.micro
- [x] Restrict DB engines to MySQL, PostgreSQL, MariaDB, Oracle BYOL, or SQL Server
- [ ] 750 hours/month of RDS database usage
- [x] 20GB of General Purpose (SSD) storage
- [ ] 20GB of DB backups and snapshots
