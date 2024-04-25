provider "aws" {
  region = "eu-west-1"
  access_key = ""
  secret_key = ""
}

resource "aws_vpc" "development-vpc"{
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "dev-subnet-1" {
  vpc_id = aws_vpc.development-vpc.id
  cidr_block = "10.0.10.0/24"
  availability_zone = "eu-west-1a"
}