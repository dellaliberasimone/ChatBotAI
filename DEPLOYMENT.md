# Containerization and AKS Deployment Guide

This guide explains how to containerize the ChatbotAI application (both frontend and backend) and deploy it to Azure Kubernetes Service (AKS).

## Prerequisites

- Azure CLI installed and logged in
- kubectl installed
- Docker installed and running
- Node.js 18+ and .NET SDK 8.0+ installed

## Local Testing with Docker Compose

Before deploying to AKS, you can test both services together using Docker Compose:

```powershell
# Build and run both services
docker-compose up --build

# Access the application at http://localhost:3000
```

## Manual Deployment Process

### 1. Build and Push Docker Images

```powershell
# Log in to Azure
az login

# Log in to Azure Container Registry
az acr login --name acrdemopn

# Build and tag backend image
docker build -t acrdemopn.azurecr.io/chatbot-backend:latest -f ./infrastructure/Dockerfile .

# Build and tag frontend image
docker build -t acrdemopn.azurecr.io/chatbot-frontend:latest -f ./frontend/Dockerfile ./frontend

# Push images to ACR
docker push acrdemopn.azurecr.io/chatbot-backend:latest
docker push acrdemopn.azurecr.io/chatbot-frontend:latest
```

### 2. Deploy to AKS

```powershell
# Connect to your AKS cluster
az aks get-credentials --resource-group scaling-aks-demo-rg --name aks-minimal-api

# Apply Kubernetes configurations
kubectl apply -k ./kubernetes/

# Check deployment status
kubectl get pods,svc,ingress

# Get the external IP address of your Ingress
kubectl get ingress chatbot-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

## Understanding Service Communication

This application uses the following approach for service communication:

### Within Kubernetes:
1. The frontend service communicates with the backend API using Kubernetes service discovery
2. The URL for the backend is configured via environment variables at runtime
3. CORS is configured to allow cross-origin requests between services

### Communication Flow:
- Frontend -> Backend: Uses the Kubernetes service name `chatbot-backend`
- External -> App: Traffic enters through the Ingress and is routed based on path:
  - `/` routes to the frontend service
  - `/api/*` routes to the backend API service

### Security:
- No hardcoded URLs or credentials
- Services connect via internal Kubernetes networking
- API authentication can be implemented using Azure AD or another identity provider

## Troubleshooting

### Check Pod Status
```powershell
kubectl get pods
kubectl describe pod [pod-name]
kubectl logs [pod-name]
```

### Check Services
```powershell
kubectl get services
kubectl describe service chatbot-backend
kubectl describe service chatbot-frontend
```

### Test Network Connectivity
```powershell
# Execute into the frontend pod
kubectl exec -it [frontend-pod-name] -- /bin/sh

# Test connectivity to backend
wget -qO- http://chatbot-backend/
```
