
provider "aws" {
  region = "ap-south-1"
}

# -----------------------------
# LATEST UBUNTU AMI
# -----------------------------
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# -----------------------------
# AZs (IMPORTANT FIX)
# -----------------------------
data "aws_availability_zones" "azs" {}

# -----------------------------
# VPC
# -----------------------------
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  enable_dns_support   = true
  enable_dns_hostnames = true
}

# -----------------------------
# INTERNET GATEWAY
# -----------------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

# -----------------------------
# ROUTE TABLE
# -----------------------------
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "a1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_route_table_association" "a2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.rt.id
}

# -----------------------------
# SUBNETS (FIXED MULTI-AZ)
# -----------------------------
resource "aws_subnet" "public1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.azs.names[0]
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.azs.names[1]
  map_public_ip_on_launch = true
}

# -----------------------------
# SECURITY GROUP
# -----------------------------
resource "aws_security_group" "app_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -----------------------------
# EC2 INSTANCES (FLASK APP)
# -----------------------------
resource "aws_instance" "app1" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public1.id
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  user_data_base64 = base64encode(file("user_data.sh"))

  tags = {
    Name = "app-server-1"
  }
}

resource "aws_instance" "app2" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public2.id
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  user_data_base64 = base64encode(file("user_data.sh"))

  tags = {
    Name = "app-server-2"
  }
}

# -----------------------------
# LOAD BALANCER
# -----------------------------
resource "aws_lb" "app_alb" {
  name               = "app-alb"
  load_balancer_type = "application"

  security_groups = [aws_security_group.app_sg.id]
  subnets         = [aws_subnet.public1.id, aws_subnet.public2.id]
}

# -----------------------------
# TARGET GROUP
# -----------------------------
resource "aws_lb_target_group" "tg" {
  name     = "app-tg"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path = "/health"
    port = "5000"
  }
}

# -----------------------------
# ATTACH EC2 TO TARGET GROUP
# -----------------------------
resource "aws_lb_target_group_attachment" "app1" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.app1.id
  port             = 5000
}

resource "aws_lb_target_group_attachment" "app2" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.app2.id
  port             = 5000
}

# -----------------------------
# LISTENER
# -----------------------------
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# -----------------------------
# RDS SUBNET GROUP (FIX)
# -----------------------------
resource "aws_db_subnet_group" "db_subnet" {
  name = "db-subnet"

  subnet_ids = [
    aws_subnet.public1.id,
    aws_subnet.public2.id
  ]
}

# -----------------------------
# RDS MYSQL DATABASE
# -----------------------------
resource "aws_db_instance" "db" {
  identifier        = "app-db"
  engine            = "mysql"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  db_name  = "appdb"
  username = "admin"
  password = "Admin12345"

  skip_final_snapshot = true

  db_subnet_group_name   = aws_db_subnet_group.db_subnet.name
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  publicly_accessible = true
}

# -----------------------------
# OUTPUTS
# -----------------------------
output "alb_dns" {
  value = aws_lb.app_alb.dns_name
}

output "db_endpoint" {
  value = aws_db_instance.db.endpoint
}

