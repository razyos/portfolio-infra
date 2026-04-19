# portfolio-infra

Production-grade AWS EKS platform provisioned with Terraform, wired to ArgoCD for GitOps-driven application delivery.

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                        AWS VPC                          │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              Public Subnets (multi-AZ)           │   │
│  │                                                  │   │
│  │   ┌──────────────────────────────────────────┐  │   │
│  │   │              EKS Cluster                 │  │   │
│  │   │                                          │  │   │
│  │   │  Control Plane (AWS-managed)             │  │   │
│  │   │    ├── API logging (api/audit/auth)      │  │   │
│  │   │    └── OIDC provider (for IRSA)          │  │   │
│  │   │                                          │  │   │
│  │   │  Managed Node Group                      │  │   │
│  │   │    ├── Auto Scaling (min/desired/max)    │  │   │
│  │   │    └── EBS volume management (IRSA)      │  │   │
│  │   │                                          │  │   │
│  │   │  EKS Add-ons                             │  │   │
│  │   │    ├── VPC-CNI  (IRSA-enabled)           │  │   │
│  │   │    ├── CoreDNS                           │  │   │
│  │   │    ├── kube-proxy                        │  │   │
│  │   │    └── EBS CSI Driver                    │  │   │
│  │   │                                          │  │   │
│  │   │  ArgoCD (Helm)                           │  │   │
│  │   │    └── App-of-Apps → github.com/razyos/  │  │   │
│  │   │                       charts             │  │   │
│  │   └──────────────────────────────────────────┘  │   │
│  │                                                  │   │
│  │   Internet Gateway ── Route Table                │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  S3 (Terraform state)  +  DynamoDB (state lock)        │
└─────────────────────────────────────────────────────────┘
```

**GitOps flow:**

```
git push → github.com/razyos/charts
               │
               └── ArgoCD (App of Apps)
                       ├── infraset     (cert-manager, ingress-nginx)
                       ├── monitoringset (Prometheus, Grafana)
                       └── appset       (application workloads)
```

---

## Modules

| Module | Responsibility |
|--------|---------------|
| `calculation` | Queries available AZs, filters by instance type support, calculates subnet CIDRs |
| `network` | VPC, Internet Gateway, public subnets (multi-AZ), security groups |
| `eks` | EKS cluster, IAM roles, managed node group, EBS volume policy |
| `eks-addons` | VPC-CNI (IRSA), CoreDNS, kube-proxy, EBS CSI Driver |
| `argocd` | ArgoCD Helm install, GitHub repo secret, root App-of-Apps |

---

## Prerequisites

- Terraform >= 1.5
- AWS CLI configured with sufficient IAM permissions
- `kubectl` and `helm` installed
- An SSH key pair added to your GitHub account, stored in **AWS Secrets Manager**
- An S3 bucket and DynamoDB table for Terraform state (see `backend-config.hcl`)

---

## Deployment

**1. Configure the backend**

Edit `backend-config.hcl` with your S3 bucket, key path, and DynamoDB table:

```hcl
bucket         = "your-terraform-state-bucket"
key            = "terraform/state/production/terraform.tfstate"
region         = "us-east-1"
encrypt        = true
dynamodb_table = "your-terraform-lock-table"
```

**2. Create your `terraform.tfvars`**

Copy `example.tfvars` and fill in your values:

```bash
cp example.tfvars terraform.tfvars
```

> `terraform.tfvars` is gitignored — never commit credentials or secrets.

**3. Store the GitHub SSH key in Secrets Manager**

```bash
aws secretsmanager create-secret \
  --name "portfolio/github-ssh-key" \
  --secret-string "$(cat ~/.ssh/id_ed25519)"
```

**4. Run Terraform**

```bash
bash run.sh
```

This initialises the backend, selects/creates the workspace, and runs `plan` → `apply`.

**5. Bootstrap ArgoCD**

After the cluster is up, run `setup.sh` to configure ArgoCD with TLS and connect it to the charts repository:

```bash
bash setup.sh
```

---

## Day-2 Operations

| Task | Command |
|------|---------|
| Destroy the cluster | `bash destroy.sh` |
| Force-clean stuck ArgoCD resources | `bash cleanargo.sh` |
| Full cluster teardown (K8s + Terraform) | `bash cleanup.sh` |

---

## Secrets management

No secrets are committed to this repository. The GitHub SSH key used by ArgoCD is stored in AWS Secrets Manager and retrieved at apply time via a `data` source:

```hcl
data "aws_secretsmanager_secret_version" "github_ssh_key" {
  secret_id = data.aws_secretsmanager_secret.github_ssh_key.id
}
```

The `*.tfvars` pattern is gitignored to prevent accidental credential commits.

---

## Repository layout

```
portfolio-infra/
├── main.tf                  # Root module — wires all modules together
├── providers.tf             # AWS, Kubernetes, Helm, kubectl providers
├── variables.tf             # Input variables
├── outputs.tf               # Cluster endpoint, OIDC provider, VPC ID
├── backend-config.hcl       # S3 backend configuration
├── example.tfvars           # Reference variable file (no secrets)
├── run.sh                   # terraform init / plan / apply wrapper
├── setup.sh                 # Post-apply ArgoCD bootstrap
├── destroy.sh               # Teardown with ELB cleanup
├── cleanup.sh               # Full K8s + Terraform teardown
├── cleanargo.sh             # Force-remove stuck ArgoCD namespace
├── cert-manager/
│   └── cluster-issuer.yaml  # Let's Encrypt ClusterIssuer
├── values/
│   └── argocd-values.yaml   # ArgoCD Helm values template
└── modules/
    ├── calculation/         # AZ + CIDR calculation
    ├── network/             # VPC and subnets
    ├── eks/                 # EKS cluster and node group
    ├── eks-addons/          # Managed add-ons with IRSA
    └── argocd/              # ArgoCD install + App of Apps
```
