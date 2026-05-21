# Terraform block to define provider requirements and versions.
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }

  required_version = ">= 1.2"
}

# Configure the AWS provider, setting the region for resource deployment.
provider "aws" {
  region = "eu-central-1"
}

# --- Web Server Resources ---

resource "aws_security_group" "grocery_web_sg" {
  name        = "grocerymate-security-group"
  description = "Security group for GroceryMate EC2"

  # Allow SSH traffic (So you can connect from your Mac)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow Web traffic for your Docker container (Port 5000)
  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow the server to access the internet (To download updates or Docker images)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # -1 means "all protocols"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "grocery_web_server" {
  # Amazon Machine Image (AMI) ID.
  # IMPORTANT: Replace this value with the AMI ID from your specific region or a previously created EC2 instance.
  ami           = "ami-0e385350f5eb99828"
  instance_type = "t2.micro"

  # Associate the EC2 instance with the web security group created above.
  vpc_security_group_ids = [aws_security_group.grocery_web_sg.id]

  tags = {
    Name = "GroceryMate-Web-Server-Terraform"
  }
}
# --- Database Resources ---

# 1. Security Group for the RDS Database
resource "aws_security_group" "grocery_db_sg" {
  name        = "grocerymate-db-security-group"
  description = "Security group for GroceryMate RDS"

  # Allow inbound traffic on port 5432 for PostgreSQL.
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    # WARNING: This allows access from ANY IP address.
    # For production, you should restrict this to the web server's security group ID.
    # Example: security_groups = [aws_security_group.grocery_web_sg.id]
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # -1 means "all protocols"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 2. RDS Database Instance (PostgreSQL)
resource "aws_db_instance" "grocery_database" {
  identifier           = "grocerymate-db-tf" # Unique name for the RDS instance.
  engine               = "postgres"
  instance_class       = "db.t3.micro"       # Use a small, cost-effective instance class for development.
  allocated_storage    = 20                  # Initial storage allocation in GB.

  # --- Credentials and Database Configuration ---
  db_name              = "grocerymate_db"
  username             = "grocery_user"
  # WARNING: Hardcoding credentials is not secure. Use a secret manager like AWS Secrets Manager in production.
  password             = "grocery_test"

  # --- Connectivity and Backup Rules ---
  publicly_accessible  = true
  skip_final_snapshot  = true                # Set to true for development to allow for quick deletion without creating a final backup.
  vpc_security_group_ids = [aws_security_group.grocery_db_sg.id]
}