# Specify the provider and access details
provider "aws" {
  region = "${var.aws_region}"
}
# Create a VPC to launch our instances into
resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
  tags {
        Name = "default_VPC"
  }
}
# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
}
# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.default.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.default.id}"
}
# Create a subnet to launch our public instances into
resource "aws_subnet" "public" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-southeast-1a"
  tags {
        Name = "public"
  }
}
# Our nat security group to access
# the instances over SSH and HTTP
resource "aws_security_group" "default_nat" {
  name        = "nat_sg"
  description = "Used in the terraform"
  vpc_id      = "${aws_vpc.default.id}"
  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # HTTP access from the VPC
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 11371
    to_port     = 11371
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_key_pair" "auth" {
  key_name   = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
}
resource "aws_instance" "nat" {
  instance_type = "t2.small"
  # Lookup the correct AMI based on the region
  # we specified
  ami = "${lookup(var.aws_amis, var.aws_region)}"
  # The name of our SSH keypair we created above.
  key_name = "${aws_key_pair.auth.id}"
  # Our Security group to allow HTTP and SSH access
  vpc_security_group_ids = ["${aws_security_group.default_nat.id}"]
  # We're going to launch into the same subnet as our ELB. In a production
  # environment it's more common to have a separate private subnet for
  # backend instances.
  subnet_id = "${aws_subnet.public.id}"
  source_dest_check = "false"
  tags {
        Name = "nat"
  }
}
resource "aws_eip" "nat" {
  instance = "${aws_instance.nat.id}"
  vpc      = true
}
resource "aws_subnet" "priv_sub_a" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-southeast-1a"
  tags {
        Name = "PRIV_SUB_A"
  }
}
resource "aws_subnet" "priv_sub_b" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "ap-southeast-1b"
  tags {
        Name = "PRIV_SUB_B"
  }
}
resource "aws_route_table" "route_table" {
    vpc_id = "${aws_vpc.default.id}"
    route {
        cidr_block = "0.0.0.0/0"
        instance_id = "${aws_instance.nat.id}"
    }
    tags {
        Name = "priv_route_table"
    }
}
resource "aws_route_table_association" "priv_sub_a" {
    subnet_id = "${aws_subnet.priv_sub_a.id}"
    route_table_id = "${aws_route_table.route_table.id}"
}
resource "aws_route_table_association" "priv_sub_b" {
    subnet_id = "${aws_subnet.priv_sub_b.id}"
    route_table_id = "${aws_route_table.route_table.id}"
}
resource "aws_security_group" "web_sg" {
  name        = "web_sg"
  description = "Web Instance Security Group"
  vpc_id      = "${aws_vpc.default.id}"
  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # HTTP access from the VPC
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 ingress {
    from_port   = 11371
    to_port     = 11371
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_key_pair" "instance_auth" {
  key_name   = "${var.instance_key_name}"
  public_key = "${file(var.instance_public_key_path)}"
}
resource "aws_instance" "APP_AZ_A_01" {
    ami = "ami-25c00c46"
    key_name = "${aws_key_pair.instance_auth.id}"
    instance_type = "t2.small"
    subnet_id = "${aws_subnet.priv_sub_a.id}"
    security_groups = ["${aws_security_group.web_sg.id}"]
    user_data = "${file("provision.sh")}"
    root_block_device {
      volume_type = "gp2"
    }
    tags {
        Name = "APP_AZ_A_01"
    }
}
resource "aws_instance" "APP_AZ_B_01" {
    ami = "ami-25c00c46"
    key_name = "${aws_key_pair.instance_auth.id}"
    instance_type = "t2.small"
    subnet_id = "${aws_subnet.priv_sub_b.id}"
    security_groups = ["${aws_security_group.web_sg.id}"]
    user_data = "${file("provision.sh")}"
    root_block_device {
      volume_type = "gp2"
    }
    tags {
        Name = "APP_AZ_B_01"
    }
}
resource "aws_security_group" "elb_sg" {
  name        = "elb_sg"
  description = "ELB Security Group"
  vpc_id      = "${aws_vpc.default.id}"
  # HTTP access from the VPC
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_elb" "instanceelb" {
  name = "instanceelb"
  subnets = ["${aws_subnet.public.id}"]
  security_groups = ["${aws_security_group.elb_sg.id}"]
  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }
  listener {
    instance_port = 8080
    instance_protocol = "http"
    lb_port = 8080
    lb_protocol = "http"
  }
  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "TCP:8080"
    interval = 30
  }
  instances = ["${aws_instance.APP_AZ_A_01.id}","${aws_instance.APP_AZ_B_01.id}"]
  cross_zone_load_balancing = true
  idle_timeout = 400
  connection_draining = true
  connection_draining_timeout = 400
  tags {
    Name = "app-elb"
  }
}
