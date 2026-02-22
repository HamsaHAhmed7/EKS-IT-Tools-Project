<!-- Add live demo GIF/video here -->

# EKS IT-Tools Platform

Cloud-native deployment of IT-Tools on Amazon EKS, demonstrating modern DevOps practices including Infrastructure as Code, GitOps workflows, automated CI/CD, and comprehensive observability.

**Live Demo:** https://it-tools.eks.hamsa-ahmed.co.uk

[![CI](https://github.com/HamsaHAhmed7/EKS-IT-Tools-Project/actions/workflows/CI-PR.yaml/badge.svg)](https://github.com/HamsaHAhmed7/EKS-IT-Tools-Project/actions/workflows/CI-PR.yaml)
[![CD](https://github.com/HamsaHAhmed7/EKS-IT-Tools-Project/actions/workflows/CD-Deploy.yaml/badge.svg)](https://github.com/HamsaHAhmed7/EKS-IT-Tools-Project/actions/workflows/CD-Deploy.yaml)

---

## Project Overview

This project deploys a developer utilities platform on AWS EKS, implementing infrastructure-as-code principles and GitOps methodologies. The deployment includes automated CI/CD pipelines, security scanning, SSL certificate management, and monitoring infrastructure.

**Architecture Highlights:**
- Multi-AZ VPC with public/private subnet separation
- EKS cluster with managed node groups
- GitOps-driven deployments via ArgoCD
- Automated certificate lifecycle management
- Integrated observability stack

![Infrastructure Architecture](./docs/architecture-diagram.png)

---

## Technology Stack

**Cloud Infrastructure**
- Amazon EKS (Kubernetes 1.34)
- AWS VPC (10.0.0.0/16 CIDR)
- Amazon Route53
- Amazon ECR
- AWS Load Balancers (NLB)

**Infrastructure Management**
- Terraform (modular design)
- Remote state management (S3 + DynamoDB)
- Pod Identity for service accounts

**Application Delivery**
- ArgoCD for GitOps
- NGINX Ingress Controller
- AWS Load Balancer Controller
- cert-manager + Let's Encrypt
- ExternalDNS

**Observability**
- Prometheus (metrics collection)
- Grafana (visualization)
- Metrics Server (HPA support)

**CI/CD & Security**
- GitHub Actions (OIDC authentication)
- Trivy (container scanning)
- Checkov (IaC validation)
- Pre-commit hooks

---

## CI/CD Pipeline

**Pull Request Validation**
- Docker build verification
- Trivy security scan (reports vulnerabilities)
- Terraform validation and formatting
- Checkov infrastructure scan
- Terraform plan generation

**Deployment Automation**
- Automated Docker image build and push to ECR
- Kubernetes manifest updates (commit SHA tagging)
- ArgoCD sync triggers deployment
- Rolling updates with configurable pod disruption budgets

![CI Workflow](./docs/terraform-ci.png)

**GitOps Flow:**
```
Code Change → PR Validation → Merge →
Build & Push → Manifest Update → ArgoCD Sync → Deployment
```

---

## Security Approach

**Shift-Left Security**

Early detection of security issues reduces remediation costs and prevents vulnerabilities from reaching production.

Implementation:
- Pre-commit hooks validate code locally before commits
- Trivy scans identify container vulnerabilities during CI
- Checkov validates infrastructure configurations against security benchmarks
- Automated dependency scanning

**Runtime Security**
- TLS 1.2+ for all external traffic
- IAM OIDC for GitHub Actions (no long-lived credentials)
- Private subnets for worker nodes
- Pod-level IAM authentication
- Network policies and security groups

---

## Cost Considerations

**Current Monthly Estimate:** ~$80-100 USD

**Breakdown:**
- EKS Control Plane: ~$73/month (flat rate)
- EC2 t3.medium instances (2): ~$30/month
- NAT Gateway: ~$32/month
- Load Balancers: ~$16-20/month
- Data transfer: ~$5/month
- Route53: <$1/month

**Cost Optimization Opportunities:**
- Spot instances for non-production workloads
- Single NAT Gateway (removes multi-AZ redundancy)
- Fargate for selective workloads
- Reserved instances for predictable workloads
- S3 lifecycle policies for logs and backups

**Trade-offs:**
- Multi-AZ deployment increases costs but improves availability
- Managed EKS control plane vs self-managed Kubernetes
- Persistent storage adds cost but required for Prometheus/Grafana data retention

---

## Live Services

**Application**
https://it-tools.eks.hamsa-ahmed.co.uk
Developer utilities collection (base64, JSON tools, hash generators, formatters)

![Application](./docs/eks-game.png)

**ArgoCD**
https://argocd.eks.hamsa-ahmed.co.uk
GitOps controller managing deployments
Credentials: `admin` / via kubectl secret retrieval

![ArgoCD](./docs/argocd.png)

**Grafana**
https://grafana.eks.hamsa-ahmed.co.uk
Monitoring dashboards and metrics visualization

![Grafana](./docs/grafana.png)

---

## Monitoring Implementation

**Metrics Collection:**
- Kubernetes API server metrics
- Node exporter (CPU, memory, disk, network)
- Pod resource usage and health
- NGINX ingress traffic metrics

**Visualization:**
- Cluster resource utilization
- Pod-level metrics
- HTTP request patterns
- Node capacity and health

![Prometheus](./docs/prometheus-target.png)

**Note:** Prometheus currently configured without persistent storage. Metrics are lost on pod restart. Production implementations would use persistent volumes or external storage solutions.

---

## Deployment Instructions

**Prerequisites:**
- AWS CLI configured
- Terraform 1.12+
- kubectl

**Deploy Infrastructure:**
```bash
cd infra
terraform init
terraform apply -var-file=terraform.tfvars
```

Deployment time: ~10-15 minutes
DNS/SSL propagation: additional 5-10 minutes

**Configure kubectl:**
```bash
aws eks update-kubeconfig --name eks-it-tools-eks-cluster --region eu-west-2
kubectl get pods -A
```

**Destroy Infrastructure:**
```bash
cd infra
terraform destroy -var-file=terraform.tfvars -auto-approve
```

---

## Project Structure
```
├── app/                    # IT-Tools application source
├── infra/
│   ├── modules/           # Terraform modules (VPC, EKS, Helm)
│   ├── kubernetes/        # Kubernetes manifests
│   ├── values/            # Helm values files
│   └── terraform.tfvars   # Infrastructure variables
├── .github/workflows/     # CI/CD pipeline definitions
└── .pre-commit-config.yaml
```

---

## Technical Capabilities Demonstrated

- Multi-module Terraform architecture
- EKS cluster provisioning and configuration
- GitOps deployment patterns
- Automated CI/CD pipeline implementation
- Container security scanning integration
- Infrastructure security validation
- SSL/TLS automation
- DNS automation
- Kubernetes ingress configuration
- Horizontal pod autoscaling
- Monitoring and observability setup
- IAM authentication for Kubernetes workloads

---

## Known Limitations

- Single NAT Gateway (cost optimization, reduces HA)
- Prometheus without persistent storage
- Grafana credentials in plaintext (should use Secrets Manager)
- Default namespace usage (production would use dedicated namespaces)
- No network policies configured
- Manual terraform apply required (no automated infrastructure changes)

---

## Future Improvements

- Implement Karpenter for advanced node autoscaling
- Add persistent storage for Prometheus
- Implement proper secrets management
- Configure network policies
- Add Terraform Cloud for remote operations
- Implement blue/green deployments
- Add application-level alerting

---

## Author

Hamsa Ahmed
DevOps Engineer

[GitHub](https://github.com/HamsaHAhmed7)

---

## License

MIT
