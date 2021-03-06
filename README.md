[![Docker Build And Push](https://github.com/devenes/terraform-docker-swarm-ecr-phonebook/actions/workflows/dockerx.yml/badge.svg)](https://github.com/devenes/terraform-docker-swarm-ecr-phonebook/actions/workflows/dockerx.yml)
[![Terraform Infrastructure Planner](https://github.com/devenes/terraform-docker-swarm-ecr-phonebook/actions/workflows/terraform_planner.yml/badge.svg)](https://github.com/devenes/terraform-docker-swarm-ecr-phonebook/actions/workflows/terraform_planner.yml)

# Automated Docker Swarm Deployment of Python Flask App using Terraform

## Description

This project aims to deploy a phonebook web application with Docker Swarm on Elastic Compute Cloud (EC2) Instances by pulling the app images from AWS Elastic Container Registry (ECR) repository using Terraform.

## Project Architecture

![Project](./readme/docker-swarm.jpg)

## Docker Swarm Cluster

![Project](./readme/swarm.png)

![Project](./readme/instances.png)

## Elastic Container Registry Repository

![Project](./readme/ecr.png)

## Terraform Outputs

![Output](./readme/logs.gif)

![Output](./readme/output.png)

## Case Study Details

- Your company has recently started a project that aims to serve as phonebook web application. Your teammates have started to work on the project and developed the UI and backend part of the project and they need your help to deploy the app in development environment.

- You are, as a Cloud/DevOps engineer, requested to deploy the Phonebook Application in the development environment on Docker Swarm on AWS EC2 Instances using Terraform to showcase the project. To do that you need to;

  - Create a new public repository for the project on GitHub.

  - Create docker image using the `Dockerfile` from the base image of `python:alpine`.

  - Deploy the app on swarm using `docker compose`. To do so on the `Compose` file;

    - Create a MySQL database service with one replica using the image of `mysql:5.7`;

      - attach a named volume to persist the data of database server.

      - attach `init.sql` file to initialize the database using `configs`.

    - Configure the app service to;

      - pull the image of the app from the AWS ECR repository.

      - deploy the one app for each swarm nodes using `global` mode.

      - run the app on `port 80`.

    - Use a user-defined overlay network for the services.

  - Push the necessary files for your project from local repo to the new github repo (phonebookswarm).

- You are also requested; to use AWS ECR as image repository, to create Docker Swarm with 3 manager and 2 worker node instances, to automate the process of Docker Swarm initialization through Terraform in the development environment. To achieve this goals, you can configure Terraform configuration file using the followings;

  - The application should run on Amazon Linux 2 EC2 Instance

  - EC2 Instance type can be configured as `t2.micro`.

  - To use the AWS ECR as image repository;

    - Enable the swarm node instances with IAM Role allowing them to work with ECR repos using the instance profile.

    - Install AWS CLI `Version 2` on swarm node instances to use `aws ecr` commands.

  - To automate the process of Docker Swarm initialization;

    - Install the docker and docker-compose on all nodes (instances) using the `user-data` bash script.

    - Create the leader manager node of the swarm. Within the `user-data` script;

      - Set the first manager node hostname as `Leader-Manager`.

      - Initialize Docker swarm.

      - Create a docker service named `viz` on the manager node on port `8080` using the `dockersamples/visualizer` image, to monitor the swarm nodes easily.

      - Build the docker image from the GitHub URL of the new project repo and tag it appropriately to push it on ECR repo. (Note: Do not forget to install Git to enable Docker to work with git commands)

      - Download `docker-compose.yml` file from the repo and deploy application stack on Docker Swarm.

    - Create two manager nodes of the swarm. Within the `user-data` script;

      - Install the python `ec2instanceconnectcli` package for `mssh` command.

      - Connect from manager node to the `Leader-Manager` to get the `join-token` and join the swarm as manager node using `mssh` command.

    - Create two worker nodes of the swarm. Within the `user-data` script;

      - Install the python `ec2instanceconnectcli` package to use `mssh` command.

      - Connect from worker node to the `Leader-Manager` to get the `join-token` and join the swarm as worker node using `mssh` command.

  - Create a security group for all swarm nodes and open necessary ports for the app and swarm services.

  - Create an image repository on ECR for the app.

  - Tag the swarm node instances appropriately as `Docker-Swarm-Manager <Number>/Docker-Swarm-Worker <Number>` to discern them from AWS Management Console.

  - The Web Application should be accessible via web browser from anywhere.

  - Phonebook App Website URL, Visualization App Website URL should be given as output by Cloudformation Service, after the stack created.

### At the end of the project, following topics are to be covered;

- Docker Swarm Deployment

- Web App and MySQL Database Configuration in Docker Swarm

- Bash scripting

- AWS ECR as Image Repository

- AWS IAM Policy and Role Configuration

- AWS EC2 Configuration

- AWS EC2 Security Group Configuration

- Terraform Configuration File

- Git & Github for Version Control System

## Resources

- [AWS CLI Command Reference](https://docs.aws.amazon.com/cli/latest/index.html)

- [Docker Compose File Reference](https://docs.docker.com/compose/compose-file/)

- [Docker Reference Page](https://docs.docker.com/reference/)

- [EC2 Instance Connect](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Connect-using-EC2-Instance-Connect.html)

- [Amazon Elastic Container Registry Documentation](https://docs.aws.amazon.com/ecr/index.html)

- [Docker Swarm](https://docs.docker.com/engine/swarm)
