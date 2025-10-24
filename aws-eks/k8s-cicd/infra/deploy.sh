#!/bin/bash

echo "Deploying AI-Ops Workshop to Kubernetes..."

# Create namespace
kubectl apply -f namespace.yaml

# Deploy application
kubectl apply -f deployment.yaml -n ai-ops-workshop

# Create ingress
kubectl apply -f ingress.yaml -n ai-ops-workshop

echo "Deployment completed!"
echo "Application will be available at: https://aiops.eoalola.people.aws.dev"
echo ""
echo "To check status:"
echo "kubectl get pods -n ai-ops-workshop"
echo "kubectl get ingress -n ai-ops-workshop"
