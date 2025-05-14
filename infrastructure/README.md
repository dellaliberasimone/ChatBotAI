# ChatbotAI Infrastructure

This directory contains the infrastructure-as-code (IaC) templates needed to deploy all required Azure resources for the ChatbotAI application.

## Prerequisites

Before deploying the infrastructure, ensure you have the following installed:

1. [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) (latest version)
2. [PowerShell 7+](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell) (if using Windows)
3. [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
4. [Docker](https://docs.docker.com/get-docker/) (for building and pushing container images)

## Files

- `infra.bicep` - The main Bicep template that defines all Azure resources
- `infra.parameters.json` - Parameters file for the Bicep deployment
- `deploy-infrastructure.ps1` - PowerShell script to automate the deployment process

## What Gets Deployed

This infrastructure deployment creates the following Azure resources:

1. **Azure Kubernetes Service (AKS)** - For hosting the application containers
2. **Azure Container Registry (ACR)** - For storing container images
3. **Azure Key Vault** - For storing secrets and configuration
4. **Azure OpenAI** - For AI capabilities
5. **Log Analytics Workspace** - For monitoring and logging
6. **Application Insights** - For application monitoring
7. **User-assigned Managed Identity** - For secure access between services

## Deployment Instructions

### 1. Deploy Infrastructure

Run the deployment script to create all the infrastructure:

```powershell
./deploy-infrastructure.ps1 -ResourceGroupName "rg-chatbot-dev" -Location "westeurope" -EnvironmentName "dev"
```

This script will:
- Create a new resource group if it doesn't exist
- Deploy all Azure resources defined in the Bicep template
- Connect to the AKS cluster
- Display the next steps for deploying your application

### 2. Build and Push Docker Images

After the infrastructure is deployed, build and push your Docker images:

```powershell
# Log in to ACR
az acr login --name <acr-name>

# Build and tag backend image
docker build -t <acr-login-server>/chatbot-backend:latest -f ./backend/Dockerfile ./backend

# Build and tag frontend image
docker build -t <acr-login-server>/chatbot-frontend:latest -f ./frontend/Dockerfile ./frontend

# Push images to ACR
docker push <acr-login-server>/chatbot-backend:latest
docker push <acr-login-server>/chatbot-frontend:latest
```

### 3. Update and Deploy Kubernetes Manifests

Update the image references in your Kubernetes manifests and deploy:

```powershell
# Apply Kubernetes configurations
kubectl apply -k ./kubernetes/
```

### 4. Verify Deployment

Check that your application is running correctly:

```powershell
# Check pod status
kubectl get pods

# Get the external IP of your application
kubectl get ingress chatbot-ingress
```

## Customization

To customize the deployment:

1. Edit `infra.parameters.json` to change default parameter values
2. For more advanced changes, modify the `infra.bicep` file directly

## Troubleshooting

If you encounter issues with your deployment, refer to the "Common Issues and Solutions" section in the `DEPLOYMENT.md` file.

## Clean Up

To remove all deployed resources:

```powershell
az group delete --name <resource-group-name> --yes --no-wait
```
