## INFRASTRUCTURE

- Public Github Repository

- Docker Swarm

  - 3 Manager nodes

  - 2 Worker nodes

    - Each of them must commminicate to each other.

    - EC2 instance connect cli

    - IAM policy

  - Leader manager node can pull/push image from/to ECR.

  - ECR policy for full-access

  - Other managers and worker nodes can pull image from ECR.

- AWS ECR to be created for image registry.

- `main.tf` terraform file

## APPLICATION

- `Dockerfile`

  - Will be used for the app-server image

  - Required files:

    - `phonebook-app.py`

    - `requirements.txt`

    - `templates` folder

- `docker-compose.yml`

  - Services:

    - app-server and my-sql

    - app-server image will be pulled from ECR.
