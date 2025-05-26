# Chatbot AI Project

This project is a chatbot application built with a .NET backend and React frontend that integrates with Azure OpenAI services. The application runs on Azure Container Apps and leverages GPT-4o mini model.

## Prerequisites

- Git
- Docker and Docker Compose (for local development)
- .NET 8.0 SDK
- Node.js 18 or later
- Azure CLI
- Azure Subscription

## Quick Setup Guide

This guide focuses on essential steps to get the application running quickly.

### 1. Deploy Azure Resources

```powershell
# Login to Azure
az login

# Create a resource group
$resourceGroup = "rg-chatbotAI"
$location = "westeurope"  # Choose a region where Azure OpenAI is available
az group create --name $resourceGroup --location $location

# 1. Create Azure Container Registry
$acrName = "acrchatbotai"  # Must be globally unique
az acr create --resource-group $resourceGroup --name $acrName --sku Basic --admin-enabled true

# 2. Create Azure OpenAI service with GPT-4o mini model
$openaiName = "openai-chatbotai"  # Must be globally unique
az cognitiveservices account create --name $openaiName --resource-group $resourceGroup --location $location --kind OpenAI --sku s0

# Deploy GPT-4o-mini model
az cognitiveservices account deployment create --name $openaiName --resource-group $resourceGroup --deployment-name "gpt-4o-mini" --model-name "gpt-4o-mini" --model-format "OpenAI" --scale-settings-scale-type "Standard"

# Get OpenAI endpoint and key
$openaiEndpoint = az cognitiveservices account show --name $openaiName --resource-group $resourceGroup --query "endpoint" -o tsv
$openaiKey = az cognitiveservices account keys list --name $openaiName --resource-group $resourceGroup --query "key1" -o tsv

# 3. Create Key Vault and store OpenAI key
$keyvaultName = "kv-chatbotai"  # Must be globally unique
az keyvault create --name $keyvaultName --resource-group $resourceGroup --location $location
az keyvault secret set --vault-name $keyvaultName --name "AzureOpenAIKey" --value $openaiKey
$keyvaultUri = az keyvault show --name $keyvaultName --resource-group $resourceGroup --query "properties.vaultUri" -o tsv

# Display important values
Write-Host "OpenAI Endpoint: $openaiEndpoint"
Write-Host "Key Vault URI: $keyvaultUri"
```

### 2. Configure Application

#### Backend Settings

Update `backend/appsettings.json` with your Azure service details:

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "AzureOpenAI": {
    "Endpoint": "YOUR_OPENAI_ENDPOINT",
    "DeploymentName": "gpt-4o-mini"
  },
  "KeyVault": {
    "Uri": "YOUR_KEYVAULT_URI",
    "SecretName": "AzureOpenAIKey"
  },
  "Cors": {
    "AllowedOrigins": ["http://localhost:3000"]
  }
}
```

Replace:
- `YOUR_OPENAI_ENDPOINT` with your OpenAI endpoint value (e.g., `https://openai-chatbotai.openai.azure.com/`)
- `YOUR_KEYVAULT_URI` with your Key Vault URI (e.g., `https://kv-chatbotai.vault.azure.net/`)

#### Frontend Settings

Create or update `frontend/.env` file:

```
REACT_APP_API_URL=http://localhost:5000
```

### 3. Run the Application Locally

```powershell
# Option 1: Using Docker Compose
docker-compose up --build

# Option 2: Run backend and frontend separately
# Backend
cd backend
dotnet run

# Frontend (in a separate terminal)
cd frontend
npm install
npm start
```

Access the application:
- Frontend: http://localhost:3000
- Backend API: http://localhost:5000

### 4. Deploy to Azure Container Apps

Use our infrastructure templates for deployment:

```powershell
# Get ACR credentials
$acrUsername = az acr credential show --name $acrName --query "username" -o tsv
$acrPassword = az acr credential show --name $acrName --query "passwords[0].value" -o tsv

# Build and push images to ACR
docker build -t $acrName.azurecr.io/chatbot-backend:latest ./backend
docker build -t $acrName.azurecr.io/chatbot-frontend:latest ./frontend
az acr login --name $acrName
docker push $acrName.azurecr.io/chatbot-backend:latest
docker push $acrName.azurecr.io/chatbot-frontend:latest

# Deploy using Bicep template (recommended)
cd infrastructure
az deployment group create --resource-group $resourceGroup --template-file container-apps-infra.bicep --parameters container-apps-infra.parameters.json acrName=$acrName acrUsername=$acrUsername acrPassword=$acrPassword openAiEndpoint=$openaiEndpoint keyVaultUri=$keyvaultUri
```

For a simpler deployment using Azure CLI:

```powershell
# Create Container Apps Environment
$envName = "chatbot-env"
az containerapp env create --name $envName --resource-group $resourceGroup --location $location

# Deploy backend
az containerapp create --name "ca-chatbot-backend" --resource-group $resourceGroup --environment $envName --image "$acrName.azurecr.io/chatbot-backend:latest" --target-port 80 --ingress external --registry-server "$acrName.azurecr.io" --registry-username $acrUsername --registry-password $acrPassword --env-vars "AzureOpenAI__Endpoint=$openaiEndpoint" "KeyVault__Uri=$keyvaultUri" "AzureOpenAI__DeploymentName=gpt-4o-mini" "KeyVault__SecretName=AzureOpenAIKey"

# Get backend URL for frontend configuration
$backendFqdn = az containerapp show --name "ca-chatbot-backend" --resource-group $resourceGroup --query properties.configuration.ingress.fqdn -o tsv

# Deploy frontend
az containerapp create --name "ca-chatbot-frontend" --resource-group $resourceGroup --environment $envName --image "$acrName.azurecr.io/chatbot-frontend:latest" --target-port 80 --ingress external --registry-server "$acrName.azurecr.io" --registry-username $acrUsername --registry-password $acrPassword --env-vars "REACT_APP_API_URL=https://$backendFqdn"

# Configure CORS on backend
$frontendFqdn = az containerapp show --name "ca-chatbot-frontend" --resource-group $resourceGroup --query properties.configuration.ingress.fqdn -o tsv
az containerapp update --name "ca-chatbot-backend" --resource-group $resourceGroup --set-env-vars "Cors__AllowedOrigins__0=https://$frontendFqdn"

# Display application URLs
Write-Host "Backend URL: https://$backendFqdn"
Write-Host "Frontend URL: https://$frontendFqdn"
```

## CI/CD with GitHub Actions

Our project includes GitHub Actions workflows to automate the build and deployment process.

### Setting up GitHub Actions

1. Add the following secrets to your GitHub repository:

   - `AZURE_CREDENTIALS`: Service principal credentials for Azure (JSON format)
   - `ACR_NAME`: Your Azure Container Registry name
   - `RESOURCE_GROUP`: Your resource group name

2. Create a service principal for GitHub Actions:

   ```powershell
   $subscriptionId = "<your-subscription-id>"  # Replace with your actual subscription ID
   az ad sp create-for-rbac --name "github-actions-chatbot" --role Contributor --scopes /subscriptions/$subscriptionId --sdk-auth
   ```

   The output JSON should be added as the `AZURE_CREDENTIALS` secret.

3. Push to the repository to trigger the workflow that will build and push Docker images to ACR.

## Project Structure

- `/backend`: .NET 8 API that communicates with Azure OpenAI
- `/frontend`: React TypeScript application for the chat interface
- `/.github/workflows`: GitHub Actions workflow files for CI/CD
- `/docker-compose.yml`: Configuration for local development

## Technologies Used

- **Backend**: .NET 8, Azure OpenAI SDK, Azure Identity
- **Frontend**: React, TypeScript, Axios
- **Deployment**: Docker, Azure Container Apps, GitHub Actions
- **Azure Services**: 
  - **Azure OpenAI**: Provides the GPT-4o mini model for chat capabilities
  - **Azure Container Registry**: Stores Docker container images
  - **Azure Key Vault**: Securely stores API keys
  - **Azure Container Apps**: Hosts both backend and frontend applications

## Troubleshooting

- **Missing Azure OpenAI permissions**: Ensure your account has access to Azure OpenAI services
- **Deployment region issues**: Make sure to deploy Azure OpenAI in a supported region
- **CORS errors**: Verify the backend Container App has proper CORS configuration for the frontend URL
- **Environment variables**: Ensure all required environment variables are set correctly in both frontend and backend
- **Authentication errors**: Check that the Key Vault identity has proper permissions to access secrets
