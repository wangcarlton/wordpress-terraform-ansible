resource "aws_security_group" "asg_sg" {
  name   = "asg_sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

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
    cidr_blocks = [var.allow_cidr_block]
  }
  # This is because dynamic port mapping, needs to handle all traffic comming from alb
  # Without this, target group checks will fail
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "instance_role" {
  name = "${var.environment}_instance_role"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": ["ec2.amazonaws.com"]
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "${var.environment}_instance_profile"
  path = "/"
  role = aws_iam_role.instance_role.name
}
resource "aws_iam_role_policy_attachment" "ec2_cloudwatch_role" {
  role       = aws_iam_role.instance_role.id
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_launch_configuration" "asg_launch_configuration" {
  name_prefix                 = "${var.environment}_${var.cluster_name}_"
  image_id                    = var.aws_ami
  instance_type               = var.instance_type
  security_groups             = [aws_security_group.asg_sg.id]
  user_data                   = data.template_file.user_data.rendered
  iam_instance_profile        = aws_iam_instance_profile.instance_profile.id
  key_name                    = var.key_name
  depends_on   = [module.db]
  associate_public_ip_address = true

  lifecycle {
    create_before_destroy = true
  }
}

data "template_file" "user_data" {
  template = file("${path.module}/user_data.sh")

  vars = {
    db_host = module.db.this_db_instance_endpoint
    db_name = var.database_name
    db_username = var.rds_user_name
    db_password = var.rds_user_password
  }
}

resource "aws_autoscaling_group" "asg" {
  name                 = "${var.environment}_"
  max_size             = var.max_size
  min_size             = var.min_size
  desired_capacity     = var.desired_capacity
  force_delete         = true
  launch_configuration = aws_launch_configuration.asg_launch_configuration.id
  vpc_zone_identifier  = module.vpc.public_subnets
  target_group_arns = [aws_alb_target_group.alb_target_group_http.arn]
}