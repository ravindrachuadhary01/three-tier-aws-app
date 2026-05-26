provider "aws" {
  region = "ap-south-1"
}

# -------------------------
# VPC
# -------------------------
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# -------------------------
# SUBNETS
# -------------------------
resource "aws_subnet" "public1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
}

# -------------------------
# SECURITY GROUP (ALL IN ONE)
# -------------------------
resource "aws_security_group" "app_sg" {
  name   = "app-sg"
  vpc_id = aws_vpc.main.id

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Flask port
  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH (optional)
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

# -------------------------
# EC2 INSTANCES (2 APP SERVERS)
# -------------------------
resource "aws_instance" "app1" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.micro"

  subnet_id              = aws_subnet.public1.id
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  user_data = file("user_data.sh")

  tags = {
    Name = "app-server-1"
  }
}

resource "aws_instance" "app2" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.micro"

  subnet_id              = aws_subnet.public2.id
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  user_data = file("user_data.sh")

  tags = {
    Name = "app-server-2"
  }
}

# -------------------------
# APPLICATION LOAD BALANCER
# -------------------------
resource "aws_lb" "app_alb" {
  name               = "app-alb"
  load_balancer_type = "application"

  security_groups = [aws_security_group.app_sg.id]
  subnets         = [aws_subnet.public1.id, aws_subnet.public2.id]
}

# -------------------------
# TARGET GROUP
# -------------------------
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

# -------------------------
# ATTACH EC2 TO TARGET GROUP
# -------------------------
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

# -------------------------
# ALB LISTENER
# -------------------------
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# -------------------------
# RDS DATABASE (MYSQL)
# -------------------------
resource "aws_db_instance" "db" {
  identifier        = "app-db"
  engine            = "mysql"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  db_name  = "appdb"
  username = "admin"
  password = "Admin12345"

  skip_final_snapshot = true

  vpc_security_group_ids = [aws_security_group.app_sg.id]

  publicly_accessible = true
}

# -------------------------
# OUTPUTS
# -------------------------
output "alb_dns" {
  value = aws_lb.app_alb.dns_name
}

output "db_endpoint" {
  value = aws_db_instance.db.endpoint
}