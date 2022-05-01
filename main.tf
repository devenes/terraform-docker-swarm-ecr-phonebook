locals {
  github-repo     = var.github-repo
  github-file-url = var.github-file-url
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {
  name = var.region
}

data "template_file" "leader-master" {
  template = <<EOF
    #! /bin/bash
    yum update -y
    hostnamectl set-hostname Leader-Manager
    amazon-linux-extras install docker -y
    systemctl start docker
    systemctl enable docker
    usermod -a -G docker ec2-user
    curl -L "https://github.com/docker/compose/releases/download/1.26.2/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    docker swarm init
    aws ecr get-login-password --region ${data.aws_region.current.name} | docker login --username AWS --password-stdin ${aws_ecr_repository.ecr-repo.repository_url}
    docker service create \
      --name=viz \
      --publish=8080:8080/tcp \
      --constraint=node.role==manager \
      --mount=type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
      dockersamples/visualizer
    yum install git -y
    # uninstall aws cli version 1
    rm -rf /bin/aws
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install
    docker build --force-rm -t "${aws_ecr_repository.ecr-repo.repository_url}:latest" ${local.github-repo}
    docker push "${aws_ecr_repository.ecr-repo.repository_url}:latest"
    mkdir -p /home/ec2-user/phonebook
    cd /home/ec2-user/phonebook && echo "ECR_REPO=${aws_ecr_repository.ecr-repo.repository_url}" > .env
    curl -o "docker-compose.yml" -L ${local.github-file-url}docker-compose.yml
    curl -o "init.sql" -L ${local.github-file-url}init.sql
    docker-compose config | docker stack deploy --with-registry-auth -c - phonebook
  EOF
}

data "template_file" "manager" {
  template = <<EOF
    #! /bin/bash
    yum update -y
    hostnamectl set-hostname Manager
    amazon-linux-extras install docker -y
    systemctl start docker
    systemctl enable docker
    usermod -a -G docker ec2-user
    curl -L "https://github.com/docker/compose/releases/download/1.26.2/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    yum install python3 -y
    amazon-linux-extras install epel -y
    yum install python-pip -y
    pip install ec2instanceconnectcli
    eval "$(mssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no  \
    --region ${data.aws_region.current.name} ${aws_instance.docker-machine-leader-manager.id} docker swarm join-token manager | grep -i 'docker')"
    # uninstall aws cli version 1
    rm -rf /bin/aws
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install
  EOF
}

data "template_file" "worker" {
  template = <<EOF
    #! /bin/bash
    yum update -y
    hostnamectl set-hostname Worker
    amazon-linux-extras install docker -y
    systemctl start docker
    systemctl enable docker
    usermod -a -G docker ec2-user
    curl -L "https://github.com/docker/compose/releases/download/1.26.2/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    yum install python3 -y
    amazon-linux-extras install epel -y
    yum install python-pip -y
    pip install ec2instanceconnectcli
    eval "$(mssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no  \
     --region ${data.aws_region.current.name} ${aws_instance.docker-machine-leader-manager.id} docker swarm join-token worker | grep -i 'docker')"
    # uninstall aws cli version 1
    rm -rf /bin/aws
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install
  EOF
}

resource "aws_ecr_repository" "ecr-repo" {
  name                 = var.ecr_repo_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
}

resource "aws_iam_role" "ec2fulltoecr" {
  name = "ec2roletoecr"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  inline_policy {
    name = "my_inline_policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          "Effect" : "Allow",
          "Action" : "ec2-instance-connect:SendSSHPublicKey",
          "Resource" : "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:instance/*",
          "Condition" : {
            "StringEquals" : {
              "ec2:osuser" : "ec2-user"
            }
          }
        },
        {
          "Effect" : "Allow",
          "Action" : "ec2:DescribeInstances",
          "Resource" : "*"
        }
      ]
    })
  }

  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"]
}

resource "aws_iam_instance_profile" "ec2ecr-profile" {
  name = var.ec2_ecr_iam_profile_name
  role = aws_iam_role.ec2fulltoecr.name
}

resource "aws_instance" "docker-machine-leader-manager" {
  ami                    = var.instance_ami
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.tf-docker-sec-gr.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2ecr-profile.name
  user_data              = data.template_file.leader-master.rendered
  # security_groups      = ["docker-swarm-sec-gr"]

  root_block_device {
    # volume_size = 16
    volume_size = 8
  }

  tags = {
    Name = "Docker-Swarm-Leader-Manager"
  }
}

resource "aws_instance" "docker-machine-managers" {
  ami                    = var.instance_ami
  instance_type          = var.instance_type
  key_name               = var.key_name
  iam_instance_profile   = aws_iam_instance_profile.ec2ecr-profile.name
  count                  = 2
  user_data              = data.template_file.manager.rendered
  depends_on             = [aws_instance.docker-machine-leader-manager]
  vpc_security_group_ids = [aws_security_group.tf-docker-sec-gr.id]
  # security_groups      = ["docker-swarm-sec-gr"]

  tags = {
    Name = "Docker-Swarm-Manager-${count.index + 1}"
  }
}

resource "aws_instance" "docker-machine-workers" {
  ami                    = var.instance_ami
  instance_type          = var.instance_type
  key_name               = var.key_name
  iam_instance_profile   = aws_iam_instance_profile.ec2ecr-profile.name
  count                  = 2
  user_data              = data.template_file.worker.rendered
  depends_on             = [aws_instance.docker-machine-leader-manager]
  vpc_security_group_ids = [aws_security_group.tf-docker-sec-gr.id]
  # security_groups      = ["docker-swarm-sec-gr"]

  tags = {
    Name = "Docker-Swarm-Worker-${count.index + 1}"
  }
}
