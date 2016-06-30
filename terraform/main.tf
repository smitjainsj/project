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
resource "aws_subnet" "public_a" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-southeast-1a"
  tags {
        Name = "public_A"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-southeast-1b"
  tags {
        Name = "public_B"
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

  instance_type = "t2.micro"

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
  subnet_id = "${aws_subnet.public_a.id}"
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
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "ap-southeast-1a"
  tags {
        Name = "PRIV_SUB_A"
  }
}

resource "aws_subnet" "priv_sub_b" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "10.0.4.0/24"
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


  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Example ELB Configuration

resource "aws_elb" "example-elb" {
  name = "example-elb"
  subnets = ["${aws_subnet.public_a.id}" ,"${aws_subnet.public_b.id}" ]
  security_groups = ["${aws_security_group.elb_sg.id}"]
#  availability_zones = ["ap-southeast-1a" , "ap-southeast-1b"]
  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  health_check {
    healthy_threshold = 10
    unhealthy_threshold = 10
    timeout = 5
    target = "TCP:80"
    interval = 60
  }

  instances = ["${aws_instance.APP_AZ_A_01.id}","${aws_instance.APP_AZ_B_01.id}"]
  cross_zone_load_balancing = true
  idle_timeout = 400
  connection_draining = true
  connection_draining_timeout = 400

  tags {
    Name = "example-elb"
  }
}

resource "aws_launch_configuration" "app_lcf_conf" {
    name_prefix = "app_lcf_conf"
    image_id = "ami-25c00c46"
    instance_type = "t2.small"
    user_data = "${file("provision.sh")}"
    security_groups = ["${aws_security_group.web_sg.id}"]
    key_name = "${var.instance_key_name}"

    lifecycle {
      create_before_destroy = true
    }
}

resource "aws_autoscaling_group" "app_asg" {
  load_balancers = ["${aws_elb.example-elb.name}"]
  vpc_zone_identifier = ["${aws_subnet.priv_sub_a.id}","${aws_subnet.priv_sub_b.id}"]
  name = "app_asg"
  max_size = 4
  min_size = 2
  health_check_grace_period = 300
  health_check_type = "ELB"
  desired_capacity = 2
  force_delete = true
  launch_configuration = "${aws_launch_configuration.app_lcf_conf.name}"
  lifecycle {
      create_before_destroy = true
    }
}

resource "aws_autoscaling_policy" "scaleup" {
    name = "scaleup"
    scaling_adjustment = 2
    adjustment_type = "ChangeInCapacity"
    cooldown = 300
    autoscaling_group_name = "${aws_autoscaling_group.app_asg.name}"
}

resource "aws_cloudwatch_metric_alarm" "scaleupcpualarm" {
    alarm_name = "scaleupcpualarm"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods = "2"
    metric_name = "CPUUtilization"
    namespace = "AWS/EC2"
    period = "120"
    statistic = "Average"
    threshold = "80"
    dimensions {
        AutoScalingGroupName = "${aws_autoscaling_group.app_asg.name}"
    }
    alarm_description = "This metric monitor ec2 cpu utilization"
    alarm_actions = ["${aws_autoscaling_policy.scaleup.arn}"]
}


resource "aws_autoscaling_policy" "scaledown" {
    name = "scaledown"
    scaling_adjustment = -2
    adjustment_type = "ChangeInCapacity"
    cooldown = 300
    autoscaling_group_name = "${aws_autoscaling_group.app_asg.name}"
}

resource "aws_cloudwatch_metric_alarm" "scaledowncpualarm" {
    alarm_name = "scaledowncpualarm"
    comparison_operator = "LessThanOrEqualToThreshold"
    evaluation_periods = "2"
    metric_name = "CPUUtilization"
    namespace = "AWS/EC2"
    period = "120"
    statistic = "Average"
    threshold = "30"
    dimensions {
        AutoScalingGroupName = "${aws_autoscaling_group.app_asg.name}"
    }
    alarm_description = "This metric monitor ec2 cpu utilization"
    alarm_actions = ["${aws_autoscaling_policy.scaledown.arn}"]
}
