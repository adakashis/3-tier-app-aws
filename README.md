# 3-Tier AWS Application - Full Infrastructure

## Architecture
- VPC (public/private/db subnets across 2 AZs)
- EKS (Web + App tiers with separate node groups)
- Aurora PostgreSQL (DB tier)
- ALB + AWS Load Balancer Controller (K8s ingress)
- WAF v2 (SQLi, XSS, rate limiting, custom rules)
- Route 53 (DNS + ACM certificate)
- Jenkins EC2 (CI/CD)

## Deployment Order

### Step 1 - Bootstrap (run once)
```bash
cd bootstrap
terraform init
terraform apply
```

### Step 2 - VPC
```bash
cd vpc
terraform init
terraform apply
```

### Step 3 - EKS
```bash
cd eks
terraform init
terraform apply
```

### Step 4 - RDS
```bash
cd rds
terraform init
terraform apply -var="db_password=<your-password>"
```

### Step 5 - WAF
```bash
cd waf
terraform init
terraform apply
```

### Step 6 - Route53 + ACM (get certificate ARN from output)
```bash
cd route53
terraform init
terraform apply -var="domain_name=yourdomain.com"
```

### Step 7 - ALB
```bash
cd alb
terraform init
terraform apply -var="acm_certificate_arn=<arn-from-step-6>"
```

### Step 8 - Jenkins
```bash
cd jenkins
terraform init
terraform apply -var="key_name=<your-key-pair>" -var="allowed_cidr=<your-ip>/32"
```

### Step 9 - Install AWS Load Balancer Controller on EKS
```bash
aws eks update-kubeconfig --region us-east-1 --name 3tier-eks

helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=3tier-eks \
  --set serviceAccount.create=true \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=<alb-controller-role-arn>
```

### Step 10 - Deploy K8s manifests
```bash
kubectl create namespace web
kubectl create namespace app
kubectl label namespace web name=web
kubectl label namespace app name=app

# Create DB secret
kubectl create secret generic db-secret -n app \
  --from-literal=host=<aurora-endpoint> \
  --from-literal=name=appdb \
  --from-literal=username=dbadmin \
  --from-literal=password=<your-password>

kubectl apply -f k8s/web/deployment.yaml
kubectl apply -f k8s/app/deployment.yaml
kubectl apply -f k8s/network-policy/network-policies.yaml
kubectl apply -f k8s/ingress/ingress.yaml
```

### Step 11 - Jenkins CI/CD
1. Open Jenkins at http://<jenkins-ip>:8080
2. Create a new Pipeline job
3. Point it to your Git repo with the Jenkinsfile
4. Update placeholders in Jenkinsfile (<your-account-id>, etc.)

## Placeholders to Replace
| Placeholder | Description |
|---|---|
| `<your-ecr-repo>` | ECR registry URL |
| `<your-account-id>` | AWS Account ID |
| `<your-acm-certificate-arn>` | ACM cert ARN from route53 output |
| `<your-waf-web-acl-arn>` | WAF ACL ARN from waf output |
| `<your-domain.com>` | Your domain name |
| `<your-key-pair>` | EC2 key pair name |
| `<your-ip>` | Your IP for Jenkins access |
