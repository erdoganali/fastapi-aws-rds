data "aws_ami" "server_ami" {
  owners = ["137112412989"]
  most_recent = true


  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-*"]
  }
}