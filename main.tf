resource "random_id" "unique_id" {
  byte_length = 4
}

resource "aws_instance" "ec2_instance" {
  ami                    = "ami-0148347da6004e644"
  instance_type          = "m5.4xlarge"                                   # vCPU: 16 -- RAM: 64GB
  iam_instance_profile   = aws_iam_instance_profile.instance_profile.name # Instance profile to allow us to upload kubeconfig to S3
  vpc_security_group_ids = [aws_security_group.security_group.id]

  root_block_device {
    volume_size           = 250
    volume_type           = "gp2"
    delete_on_termination = true
  }

  user_data = file("init-cluster.sh")

  depends_on = [
    module.s3
  ]
}

resource "aws_security_group" "security_group" {
  name        = "kube-api-access-${random_id.unique_id.hex}"
  description = "Allow Kube API access only from GitHub runner"

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["${var.client_ip}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "upload_kubeconfig-${random_id.unique_id.hex}"
  role = aws_iam_role.instance_role.name
}

resource "aws_iam_role" "instance_role" {
  name = "upload_kubeconfig-${random_id.unique_id.hex}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "s3_policy" {
  name        = "upload_kubeconfig_s3_policy-${random_id.unique_id.hex}"
  description = "Allows uploading files to S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "s3:PutObject"
        Resource = "${module.s3.s3_bucket_arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = "s3:ListAllMyBuckets"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3" {
  role       = aws_iam_role.instance_role.name
  policy_arn = aws_iam_policy.s3_policy.arn
}

module "s3" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "v3.10.1"

  bucket_prefix = "lucas-dev-"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  force_destroy = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = aws_kms_key.s3_key.id
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

resource "aws_kms_key" "s3_key" {
  description             = "KMS key used to encrypt bucket objects"
  enable_key_rotation     = true
  deletion_window_in_days = 7
}

resource "aws_kms_key_policy" "s3_kms_key_policy" {
  key_id = aws_kms_key.s3_key.id
  policy = jsonencode({
    Id = "Allow Access to KMS Key"
    Statement = [
      {
        Action = "kms:*"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Resource = "*"
      },
    ]
    Version = "2012-10-17"
  })
}
