# Testing environments for CronoQueue

## Prerequisite
* AWS account
* Terraform v0.12 https://www.terraform.io/
* Add private key to ssh agent (`ssh-add path to key`)

## Structure
* 1 dedicated VPC
* 1 public subnet
* 1 private subnet

## Launch environment
```bash
# cd to root project
cd cassandra   
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
#     - wait until all minions send connection request
#     - wait and retry until all grains set
#     - after this step can be automated
         
salt '*' state.apply

# create cassandra tables
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
