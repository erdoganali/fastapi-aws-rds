resource "aws_vpc" "mlops_vpc" {
  cidr_block           = "10.123.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "dev"
  }
}

resource "aws_subnet" "mlops_public_subnet" {
  cidr_block              = "10.123.1.0/24"
  vpc_id                  = aws_vpc.mlops_vpc.id
  map_public_ip_on_launch = true
  availability_zone       = "eu-central-1a"

  tags = {
    Name = "dev-public"
  }
}


resource "aws_internet_gateway" "mlops_internet_gateway" {
  vpc_id = aws_vpc.mlops_vpc.id

  tags = {
    Name = "dev-igw"
  }
}

resource "aws_route_table" "mlops_public_rt" {
  vpc_id = aws_vpc.mlops_vpc.id

  tags = {
    Name = "dev-public-rt"
  }
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.mlops_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.mlops_internet_gateway.id
}

resource "aws_route_table_association" "mlops_public_assoc" {
  route_table_id = aws_route_table.mlops_public_rt.id
  subnet_id      = aws_subnet.mlops_public_subnet.id
}

resource "aws_security_group" "mlops_sg" {
  name = "dev-sg"
  description = "Dev security group"
  vpc_id = aws_vpc.mlops_vpc.id

  ingress {
    from_port = 0
    protocol  = "-1"
    to_port   = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    protocol  = "-1"
    to_port   = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "mlops_auth" {
  public_key = file("~/.ssh/mlkey.pub")
  key_name = "mlkey"
}

#################  rds mysql db instance ###############

resource "aws_subnet" "mlops_public_subnet_2" {
  cidr_block              = "10.123.2.0/24"
  vpc_id                  = aws_vpc.mlops_vpc.id
  map_public_ip_on_launch = true
  availability_zone       = "eu-central-1b"

  tags = {
    Name = "dev-public-2"
  }
} 

resource "aws_security_group" "rds_security_group" {
  name        = "rds-SecurityGroup"
  description = "RDS security group"
  vpc_id      = aws_vpc.mlops_vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-SecurityGroup"
  }
}
resource "aws_db_subnet_group" "rds_mysql_subnet_group" {
  name       = "rds-mysql-subnet-group"
  subnet_ids = [aws_subnet.mlops_public_subnet.id, aws_subnet.mlops_public_subnet_2.id]

  tags = {
    Name = "rds-mysql-subnet-group"
  }
}

resource "aws_db_instance" "mlops_db" {
  allocated_storage    = 10
  storage_type         = "gp2"
  db_name              = "mlops"
  identifier           = "mlops"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"  
  username             = "mlops_user"
  password             = "Ankara06"
  port                 = 3306
  parameter_group_name = "default.mysql5.7"  
  vpc_security_group_ids = [aws_security_group.rds_security_group.id]
  db_subnet_group_name  = aws_db_subnet_group.rds_mysql_subnet_group.id
  tags = {
    Name = "mlops-db-instance"
  } 
  skip_final_snapshot = true
  publicly_accessible =  true
}
 

#######################  aws_s3_bucket  ####################### 

resource "aws_s3_bucket" "mlops_bucket" {
  bucket = "mlops-miuul-bucket"
  acl    = "private"

  tags = {
    Name = "mlops-bucket"
  }
}

resource "aws_s3_object" "mlops_bucket_object" {
  bucket = aws_s3_bucket.mlops_bucket.id
  key    = "pipeline_churn_random_forest.pkl"
  source = "../src/saved_model/pipeline_churn_random_forest.pkl"
}


######################## ec2_instance ########################


resource "aws_instance" "mlops_dev_node" {
  instance_type = "t2.micro"
  ami = data.aws_ami.server_ami.id
  key_name = aws_key_pair.mlops_auth.key_name
  vpc_security_group_ids = [aws_security_group.mlops_sg.id]
  subnet_id = aws_subnet.mlops_public_subnet.id
  user_data = <<-EOF
              #!/bin/bash
              sudo yum -y update
              sudo yum -y install git
              python3 -m pip install virtualenv
              python3 -m virtualenv fastapi
              source /fastapi/bin/activate 
              git clone https://github.com/erdoganali/fastapi-aws-rds.git
              cd /fastapi-aws-rds/src/
              pip install -r requirements.txt              
              export DATABASE_URL="mysql+pymysql://${aws_db_instance.mlops_db.username}:${aws_db_instance.mlops_db.password}@${aws_db_instance.mlops_db.endpoint}/${aws_db_instance.mlops_db.db_name}"
							echo DATABASE_URL=$DATABASE_URL >> /fastapi-aws-rds/src/.env      
              echo DATABASE_ENDPOINT="${aws_db_instance.mlops_db.endpoint}" >> /fastapi-aws-rds/src/.env    
              echo DATABASE_USER = "${aws_db_instance.mlops_db.username}" >> /fastapi-aws-rds/src/.env    
              echo DATABASE_PASSWORD ="${aws_db_instance.mlops_db.password}" >> /fastapi-aws-rds/src/.env    
              echo DATABASE_HOST = "${aws_db_instance.mlops_db.endpoint}" >> /fastapi-aws-rds/src/.env    
              echo DATABASE_PORT = "${aws_db_instance.mlops_db.port}"  >> /fastapi-aws-rds/src/.env    
              echo DATABASE_NAME = "${aws_db_instance.mlops_db.db_name}" >> /fastapi-aws-rds/src/.env 
              echo S3_BUCKET=mlops-miuul-bucket >> /fastapi-aws-rds/src/.env
              echo S3_KEY=pipeline_churn_random_forest.pkl >> /fastapi-aws-rds/src/.env              
              export AWS_ACCESS_KEY_ID=******************
              export AWS_SECRET_ACCESS_KEY******************
              export AWS_REGION=eu-central-1
              echo "AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID" >> /fastapi-aws-rds/src/.env
              echo "AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY" >> /fastapi-aws-rds/src/.env
              echo "AWS_REGION=$AWS_REGION" >> /fastapi-aws-rds/src/.env
              uvicorn main:app --host 0.0.0.0 --port 8000 --reload
              EOF
 


  tags = {
    Name = "mlops-dev-node"
  }

  root_block_device {
    volume_size = 8
  } 

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("~/.ssh/mlkey.pem")
    host        = aws_instance.mlops_dev_node.public_ip
  }

}
 