variable "instance_type" {
  default = "t2.micro"
}

variable "key_name" {
  default = "east1"
}

variable "region" {
  default = "us-east-1"
}

variable "sg-ports" {
  default     = [80, 22, 2377, 7946, 8080]
  description = "List of ports to open in the security group"
}

variable "github-repo" {
  default = "https://github.com/devenes/terraform-docker-swarm-ecr-phonebook.git"
}

variable "github-file-url" {
  default = "https://raw.githubusercontent.com/devenes/terraform-docker-swarm-ecr-phonebook/master/"
}

variable "docker_sec_gr_name" {
  default     = "docker-swarm-sec-gr"
  description = "Name of the security group to be created"
}

variable "ecr_repo_name" {
  default     = "devenes-repo/phonebook-app"
  description = "The name of the ECR repository"
}

variable "ec2_ecr_iam_profile_name" {
  default     = "swarmprofile"
  description = "The name of the IAM profile to be used by the EC2 instances to access the ECR repository"
}

variable "instance_ami" {
  default     = "ami-087c17d1fe0178315"
  description = "The AMI to use for the EC2 instances"
}
