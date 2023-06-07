# fastapi-aws-rds
terraform init 

terraform validate   

terraform plan

terraform apply --auto-approve

terraform destroy --auto-approve


ssh-keygen -t rsa -b 2048 -f ~/.ssh/mlops-central-key 

resource "aws_key_pair" "mlops_auth" {
  public_key = file("~/.ssh/mlops-central-key.pub")
  key_name = "mlops-aws-key"
}


export DATABASE_URL="mysql+pymysql://mlops_user:Ankara06@mlops-db.cw17zk3pwfhh.eu-west-1.rds.amazonaws.com/mlops-db"
