# Deployment Guide

## 🚀 Complete Deployment Steps

### Prerequisites Checklist

- [ ] AWS CLI configured with appropriate permissions
- [ ] Docker installed and running
- [ ] kubectl configured for EKS cluster
- [ ] Node.js 18+ installed
- [ ] Amazon EKS cluster running in eu-west-1
- [ ] AWS Load Balancer Controller installed on EKS

### Step 1: Local Development Setup

```bash
# Clone or navigate to project directory
cd k8s-cicd

# Install dependencies
npm install

# Start development server
npm start

# Verify application runs on http://localhost:3000
# Verify health endpoint: http://localhost:3000/health
```

### Step 2: Docker Build and Test

```bash
# Build Docker image
docker build --platform linux/amd64 -t ai-ops-react-app:latest .

# Test container locally
docker run -d -p 3000:3000 --name ai-ops-test ai-ops-react-app:latest

# Verify container health
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/health
# Should return: 200

# Clean up test container
docker stop ai-ops-test && docker rm ai-ops-test
```

### Step 3: Amazon ECR Setup

```bash
# Create ECR repository (if not exists)
aws ecr create-repository \
    --repository-name ai-ops \
    --region eu-west-1 \
    --encryption-configuration encryptionType=AES256 \
    --image-scanning-configuration scanOnPush=true

# Get login token and authenticate Docker
aws ecr get-login-password --region eu-west-1 | \
    docker login --username AWS --password-stdin \
    ACCOUNT_ID.dkr.ecr.eu-west-1.amazonaws.com

# Tag image for ECR
docker tag ai-ops-react-app:latest \
    ACCOUNT_ID.dkr.ecr.eu-west-1.amazonaws.com/ai-ops:latest

# Push to ECR
docker push ACCOUNT_ID.dkr.ecr.eu-west-1.amazonaws.com/ai-ops:latest
```

### Step 4: CodeBuild Project Setup

#### Create CodeBuild Project

```bash
# Create CodeBuild project (replace with your values)
aws codebuild create-project \
    --name "ai-ops-workshop-build" \
    --source type=GITHUB,location=https://github.com/your-username/your-repo.git \
    --artifacts type=S3,location=your-s3-bucket/artifacts \
    --environment type=LINUX_CONTAINER,image=aws/codebuild/amazonlinux2-x86_64-standard:5.0,computeType=BUILD_GENERAL1_MEDIUM,privilegedMode=true \
    --service-role arn:aws:iam::ACCOUNT_ID:role/CodeBuildServiceRole \
    --region eu-west-1
```

#### Required Environment Variables

Set these in your CodeBuild project:

```bash
ACCOUNT_ID=ACCOUNT_ID
AWS_DEFAULT_REGION=eu-west-1
```

#### Required IAM Permissions

CodeBuild service role needs:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:GetAuthorizationToken",
                "ecr:PutImage",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
```

### Step 5: Kubernetes Deployment

#### Manual Deployment

```bash
# Navigate to infra directory
cd infra

# Update deployment.yaml with your account ID (if not using CodeBuild)
sed -i 's/ACCOUNT_ID/ACCOUNT_ID/g' deployment.yaml

# Deploy to EKS
kubectl apply -f namespace.yaml
kubectl apply -f deployment.yaml -n ai-ops-workshop
kubectl apply -f ingress.yaml -n ai-ops-workshop

# Or use the deployment script
./deploy.sh
```

#### Verify Deployment

```bash
# Check namespace
kubectl get namespaces | grep ai-ops-workshop

# Check pods
kubectl get pods -n ai-ops-workshop

# Check service
kubectl get svc -n ai-ops-workshop

# Check ingress
kubectl get ingress -n ai-ops-workshop

# View pod logs
kubectl logs -f deployment/ai-ops-react-app -n ai-ops-workshop
```

### Step 6: DNS Configuration

#### Option 1: Route 53 (Recommended)

```bash
# Get ALB DNS name
ALB_DNS=$(kubectl get ingress ai-ops-react-app-ingress -n ai-ops-workshop -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Create Route 53 record (replace with your hosted zone ID)
aws route53 change-resource-record-sets \
    --hosted-zone-id Z1234567890ABC \
    --change-batch '{
        "Changes": [{
            "Action": "CREATE",
            "ResourceRecordSet": {
                "Name": "aiops.eoalola.people.aws.dev",
                "Type": "CNAME",
                "TTL": 300,
                "ResourceRecords": [{"Value": "'$ALB_DNS'"}]
            }
        }]
    }'
```

#### Option 2: Local Testing

```bash
# Get ALB DNS name
kubectl get ingress ai-ops-react-app-ingress -n ai-ops-workshop

# Add to /etc/hosts for local testing
echo "$(dig +short <ALB_DNS_NAME>) aiops.eoalola.people.aws.dev" | sudo tee -a /etc/hosts
```

### Step 7: Verification

#### Health Checks

```bash
# Test health endpoint
curl -I https://aiops.eoalola.people.aws.dev/health
# Expected: HTTP/2 200

# Test main application
curl -s https://aiops.eoalola.people.aws.dev/ | grep -o "AI-Ops Workshop"
```

#### Monitoring

```bash
# Watch pod status
kubectl get pods -n ai-ops-workshop -w

# View detailed pod information
kubectl describe pod <pod-name> -n ai-ops-workshop

# Check ingress events
kubectl describe ingress ai-ops-react-app-ingress -n ai-ops-workshop

# View ALB logs (if enabled)
aws logs describe-log-groups --log-group-name-prefix "/aws/applicationloadbalancer"
```

## 🔧 Troubleshooting

### Common Issues

#### 1. Pods Not Starting

```bash
# Check pod events
kubectl describe pod <pod-name> -n ai-ops-workshop

# Common causes:
# - Image pull errors (check ECR permissions)
# - Resource constraints (check node capacity)
# - Health check failures (check /health endpoint)
```

#### 2. Ingress Not Working

```bash
# Check ALB controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller

# Verify ALB controller is installed
kubectl get deployment -n kube-system aws-load-balancer-controller

# Check ingress annotations
kubectl get ingress ai-ops-react-app-ingress -n ai-ops-workshop -o yaml
```

#### 3. Health Check Failures

```bash
# Test health endpoint directly on pod
kubectl port-forward pod/<pod-name> 3000:3000 -n ai-ops-workshop
curl http://localhost:3000/health

# Check container logs
kubectl logs <pod-name> -n ai-ops-workshop
```

### Cleanup

```bash
# Remove application
kubectl delete -f infra/ingress.yaml -n ai-ops-workshop
kubectl delete -f infra/deployment.yaml -n ai-ops-workshop
kubectl delete -f infra/namespace.yaml

# Remove ECR images
aws ecr batch-delete-image \
    --repository-name ai-ops \
    --image-ids imageTag=latest \
    --region eu-west-1

# Remove ECR repository
aws ecr delete-repository \
    --repository-name ai-ops \
    --region eu-west-1 \
    --force
```

## 📊 Performance Optimization

### Resource Tuning

```yaml
# Adjust based on actual usage
resources:
  requests:
    memory: "64Mi"   # Minimum for small apps
    cpu: "50m"       # Minimum for light load
  limits:
    memory: "512Mi"  # Maximum for high traffic
    cpu: "500m"      # Maximum for CPU intensive
```

### Scaling

```bash
# Horizontal scaling
kubectl scale deployment ai-ops-react-app --replicas=5 -n ai-ops-workshop

# Vertical scaling (update deployment.yaml)
kubectl apply -f deployment.yaml -n ai-ops-workshop
```

### Monitoring Setup

```bash
# Install metrics server (if not present)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# View resource usage
kubectl top pods -n ai-ops-workshop
kubectl top nodes
```
