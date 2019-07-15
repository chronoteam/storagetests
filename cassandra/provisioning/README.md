# Testing environments for CronoQueue

## Prerequisite
* AWS account
* Terraform v0.12 https://www.terraform.io/
* Add private key to ssh agent (`ssh-add path to key`)

## Structure
### infrastructure
* 1 dedicated VPC
* 1 public subnet
* 1 private subnet

### machines
* 1 bastion
* x cassandra (seeds + nodes)

## Launch environment
```bash
# cd to root project
cd cassandra/provisioning   
cp secrets.tf.example secrets.tf 
  
# complete with your AWS credentials into secretes.tf file   
terraform init
terraform apply

# DONE infrastructure is ready and it need provision
```

## Provision infrastructure
```bash
# connect ssh to provision machine
tools/provision-connect.sh
sudo su

# launch infrastructure by saltstack (idempotent)
/tmp/upload/install.sh

# TODO - in progress!
# after reduce number of machines will not work

# create cassandra tables (run this inside provision machine)
# TODO automate this
/tmp/upload/create-cassandra-tables.sh

# DONE you have infrastructure provisioned and up   
```
## Tools
```bash
# ssh into provision machine
tools/provision-connect.sh

# sync files from provision/upload to provision machine (run after any change)
tools/sync-upload.sh

# *run them from root project directory (they are using relative path)
```

## Configs
* cassandra/provision/upload/config/cassandra.yaml
* cassandra/provision/upload/config/cassandra-schema.cql
