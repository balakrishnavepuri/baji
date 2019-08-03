provider "aws" {
  access_key = "AKIAQA3B2VKRU3BM2LIA"
  secret_key = "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"

  region     = "us-east-1"
}

resource "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "myvpc"
  }
}

resource "aws_subnet" "publicsubnet" {
  vpc_id                  = "${aws_vpc.myvpc.id}"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "publicsubnet"
  }
}

resource "aws_subnet" "privatesubnet" {
  vpc_id                  = "${aws_vpc.myvpc.id}"
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "privatesubnet"
  }
}

resource "aws_internet_gateway" "myigw" {
  vpc_id = "${aws_vpc.myvpc.id}"

  tags = {
    Name = "myigw"
  }
}

resource "aws_route_table" "publiceroutetable" {
  vpc_id = "${aws_vpc.myvpc.id}"

  tags = {
    Name = "publicroutetable"
  }
}

resource "aws_route_table" "privateroutetable" {
  vpc_id = "${aws_vpc.myvpc.id}"

  tags = {
    Name = "privateroutetable"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = "${aws_subnet.publicsubnet.id}"
  route_table_id = "${aws_route_table.publiceroutetable.id}"
}

resource "aws_route_table_association" "private" {
  subnet_id      = "${aws_subnet.privatesubnet.id}"
  route_table_id = "${aws_route_table.privateroutetable.id}"
}

resource "aws_route" "internet_access" {
  route_table_id         = "${aws_route_table.publiceroutetable.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.myigw.id}"
}

resource "aws_security_group" "mysg" {
  name        = " Allow SSH and HTTP"
  description = "My Security Group"
  vpc_id      = "${aws_vpc.myvpc.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance webserver" {
  connection = {
    user = "ubuntu"
  }

  instance_type               = "t2.micro"
  ami                         = "ami-07b4156579ea1d7ba"
  key_name                    = "ansible"
  subnet_id                   = "${aws_subnet.publicsunet.id}"
  vpc_security_group_ids      = ["${aws_security_group.mysg.id}"]
  monitoring                  = "true"
  associate_public_ip_address = "true"
  count                       = "1"
}

provisioner "remote-exec" {
    inline = [
      "sudo apt-get -y update",
      "sudo apt-get -y install nginx",
      "sudo service nginx start",
    ]

}



