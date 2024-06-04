resource "aws_default_vpc" "insecure_vpc" {
  tags = {
    Name = "Default VPC"
   }
}

resource "aws_default_subnet" "insecure_subnet" {
  availability_zone = "${var.region}-1a"

  tags = {
    Name = "Default subnet for us-west-2a"
  }
}

resource "aws_security_group" "insecure_sg" {
  name        = "insecure-sg"
  description = ""

  // Open all inbound traffic from any source
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = aws_default_vpc.insecure_vpc.id
}

resource "aws_instance" "insecure_instance" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  // Insecure: Assign a public IP directly to the instance
  associate_public_ip_address = true

  // Insecure: Use a hardcoded SSH key (private key should not be exposed)
  key_name = "insecure-key"

  // Insecure: Open SSH access to the world
  security_groups = [aws_security_group.insecure_sg.name]

  // Insecure: Not use the default VPC for Terraform workflows.
  // Potential security risk: Default VPC does not have a lot of the critical security features that standard VPC comes with.

  root_block_device {
    encrypted = false
    volume_size = 8
    volume_type = "standard"
  }
  user_data = templatefile("templates/linux_userdata.tpl", {
    AWS_ACCESS_KEY_ID     = var.aws_access_key_id
    AWS_SECRET_ACCESS_KEY = var.aws_secret_access_key
    AWS_DEFAULT_REGION    = var.aws_region
  })

}

resource "aws_ebs_volume" "insecure_volume" {
  availability_zone = "eu-west-1a"
  encrypted         = false
  size              = 40

  tags = {
    Name = "bad_example"
  }
}

resource "aws_volume_attachment" "insecure_volume_attachment" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.insecure_volume.id
  instance_id = aws_instance.insecure_instance.id
}