# Production Deployment to AWS EKS

Deploying the MERN stack (MongoDB, Express, React, Node.js) application on AWS EKS (Elastic Kubernetes Service) with Terraform infrastructure as code.

## Project Overview

This project demonstrates a production-ready deployment of a web application using modern DevOps practices and cloud-native technologies:

- **Infrastructure**: AWS EKS provisioned with Terraform
- **Container Orchestration**: Kubernetes
- **Ingress**: NGINX Ingress Controller
- **SSL/TLS**: cert-manager with Let's Encrypt
- **Autoscaling**: Horizontal Pod Autoscaler

## Prerequisites

Before you begin, ensure you have the following tools installed:

- [AWS CLI](https://aws.amazon.com/cli/) - Configured with appropriate credentials
- [Terraform](https://www.terraform.io/downloads.html) - v1.0.0 or newer
- [kubectl](https://kubernetes.io/docs/tasks/tools/) - For interacting with the Kubernetes cluster
- [Helm](https://helm.sh/docs/intro/install/) - For installing Kubernetes applications
- [eksctl](https://eksctl.io/installation/) - For additional EKS management

## Deployment Guide

### 1. Set up Terraform Backend (Optional but Recommended)

Before initializing Terraform, set up a remote backend to store the Terraform state securely:

**For Linux/macOS:**
```bash
# Make the script executable
chmod +x ./scripts/setup-terraform-backend.sh

# Run the script to create S3 bucket and DynamoDB table for state management
./scripts/setup-terraform-backend.sh
```

### 2. Infrastructure Provisioning with Terraform

Create the AWS infrastructure using Terraform:

```bash
# Initialize Terraform with the backend configuration
terraform init

# Preview the changes
terraform plan

# Apply the changes
terraform apply --auto-approve
```

### 3. Configure kubectl to use the new EKS cluster

```bash
aws eks --region eu-north-1 update-kubeconfig --name prod-demo-cluster
```

### 4. Set up OIDC provider for EKS

```bash
eksctl utils associate-iam-oidc-provider --region eu-north-1 --cluster prod-demo-cluster --approve
```

### 5. Create IAM service account for EBS CSI driver

```bash
eksctl create iamserviceaccount \
  --region=eu-north-1 \
  --cluster=prod-demo-cluster \
  --namespace=kube-system \
  --name=ebs-csi-controller-sa \
  --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
  --approve \
  --override-existing-service-accounts
```

### 6. Install EBS CSI driver

```bash
kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/ecr/?ref=release-1.11"
```

### 7. Install NGINX Ingress Controller

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml
```

### 8. Install cert-manager for SSL/TLS certificates

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.12.0/cert-manager.yaml
```

### 9. Create namespace for the application

```bash
kubectl create namespace mern-devops
```

### 10. Deploy the application

```bash
kubectl apply -f kubernetes/
```

### 11. Access the application

```bash
# Get the Ingress external IP/hostname
kubectl get ingress -n mern-devops
```

### 12. Clean up resources when done

```bash
# Destroy all resources created by Terraform
terraform destroy --auto-approve
```

## Configuration

### Terraform Backend

The project uses an S3 bucket with DynamoDB for state locking to store the Terraform state securely. This allows for team collaboration and prevents state corruption. The configuration is in `terraform/backend.tf`.

To customize the backend configuration:
1. Edit the bucket name and DynamoDB table name in `terraform/backend.tf`
2. Update the same values in the setup scripts in the `scripts/` directory

### Docker Images

The Kubernetes manifests reference the following Docker images:

- Backend: `atkaridarshan04/bookstore-backend:prod-v1`
- Frontend: `atkaridarshan04/bookstore-frontend:prod-v1`
- MongoDB: `mongo:4.4`

## Scaling

The application is configured with Horizontal Pod Autoscalers (HPA) for both frontend and backend services. The HPA will scale the number of pods based on CPU utilization:

- Min replicas: 1
- Max replicas: 5
- Target CPU utilization: 70%

## Storage

The application uses AWS EBS volumes for persistent storage with the following configuration:

- Storage Class: `ebs-sc` using the EBS CSI driver
- Volume Type: gp3
- File System: ext4
- Reclaim Policy: Retain

## Networking

The application is exposed through an NGINX Ingress Controller with the following paths:

- `/` - Frontend application
- `/books` - Backend API