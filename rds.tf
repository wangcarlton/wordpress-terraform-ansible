resource "aws_security_group" "db_sg" {
  name   = "db-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.asg_sg.id]
  }

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 2.0"

  identifier = var.rds_name

  engine            = "mysql"
  engine_version    = "8.0.16"
  instance_class    = "db.t2.micro"
  allocated_storage = 5

  name     = var.database_name
  username = var.rds_user_name
  password = var.rds_user_password
  port     = var.rds_port

  # DB parameter group
  family = "mysql8.0"

  # DB option group
  major_engine_version = "8.0"

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"
  backup_retention_period = 0

  vpc_security_group_ids = [aws_security_group.db_sg.id]

  # DB subnet group
  subnet_ids = module.vpc.private_subnets
}