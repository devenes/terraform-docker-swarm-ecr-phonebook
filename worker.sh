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