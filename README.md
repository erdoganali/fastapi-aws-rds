# fastapi-aws-rds
terraform init 

terraform validate   

terraform plan

terraform apply --auto-approve

terraform destroy --auto-approve

terraform destroy -target=aws_instance.mlops_dev_node

ssh-keygen -t rsa -b 2048 -f ~/.ssh/mlops-central-key 

resource "aws_key_pair" "mlops_auth" {
  public_key = file("~/.ssh/mlops-central-key.pub")
  key_name = "mlops-aws-key"
}


export DATABASE_URL="mysql+pymysql://mlops_user:Ankara06@mlops-db.cw17zk3pwfhh.eu-west-1.rds.amazonaws.com/mlops-db"

source /fastapi/bin/activate

uvicorn main:app --host 0.0.0.0 --port 8000 --reload

sudo systemctl status uvicorn

 ssh -i "~/.ssh/mlops-central-key.pub" ec2-user@ec2-18-195-216-178.eu-central-1.compute.amazonaws.com

