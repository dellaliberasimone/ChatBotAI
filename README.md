# Chatbot AI Project

This project is a chatbot application built with a .NET backend and React frontend that integrates with Azure OpenAI services. The application can be run locally using Docker Compose or deployed to Azure Container Apps.

## Prerequisites

- Git
- Docker and Docker Compose
- .NET 8.0 SDK
- Node.js 18 or later
- Azure CLI
- Azure Subscription

## Getting Started

### 1. Clone the Repository

```powershell
git clone https://github.com/dellaliberasimone/ChatBotAI
cd chatbot
```

### 2. Deploy Required Azure Resources

Before running the application, you need to deploy the following Azure resources:

#### 2.1 Azure Container Registry (ACR)

```powershell
# Login to Azure
az login

# Create a resource group if you don't have one
$resourceGroup = "rg-chatbotAI"
$location = "westeurope"
az group create --name $resourceGroup --location $location

# Create Azure Container Registry
$acrName = "acrchatbotai"
az acr create --resource-group $resourceGroup --name $acrName --sku Basic --admin-enabled true

# Get ACR credentials
$acrUsername = az acr credential show --name $acrName --query "username" -o tsv
$acrPassword = az acr credential show --name $acrName --query "passwords[0].value" -o tsv

Write-Host "ACR Username: $acrUsername"
Write-Host "ACR Password: $acrPassword"
```

#### 2.2 Azure OpenAI Service

```powershell
# Create Azure OpenAI service
$openaiName = "openai-chatbotai"
az cognitiveservices account create --name $openaiName --resource-group $resourceGroup --location $location --kind OpenAI --sku s0

# Deploy GPT-4o-mini model
az cognitiveservices account deployment create --name $openaiName --resource-group $resourceGroup --deployment-name "gpt-4o" --model-name "gpt-4o" --model-version "2023-05-15" --model-format "OpenAI" --scale-settings-scale-type "Standard"

# Get the OpenAI endpoint
$openaiEndpoint = az cognitiveservices account show --name $openaiName --resource-group $resourceGroup --query "endpoint" -o tsv

# Get the OpenAI key
$openaiKey = az cognitiveservices account keys list --name $openaiName --resource-group $resourceGroup --query "key1" -o tsv

Write-Host "OpenAI Endpoint: $openaiEndpoint"
Write-Host "OpenAI Key: $openaiKey"
```

#### 2.3 Azure Key Vault

```powershell
# Create Azure Key Vault
$keyvaultName = "kv-chatbotai"
az keyvault create --name $keyvaultName --resource-group $resourceGroup --location $location

# Store OpenAI API Key in Key Vault
az keyvault secret set --vault-name $keyvaultName --name "AzureOpenAIKey" --value $openaiKey

# Get Key Vault URI
$keyvaultUri = az keyvault show --name $keyvaultName --resource-group $resourceGroup --query "properties.vaultUri" -o tsv

Write-Host "Key Vault URI: $keyvaultUri"
```

### 3. Configure Application Settings

#### 3.1 Backend Settings

Create or update `appsettings.json` with your Azure service details:

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
    "Endpoint": "YOUR_OPENAI_ENDPOINT"
  },
  "KeyVault": {
    "Uri": "YOUR_KEYVAULT_URI"
  },
  "Cors": {
    "AllowedOrigins": ["http://localhost:3000"]
  }
}
```

Replace `YOUR_OPENAI_ENDPOINT` with your OpenAI endpoint value and `YOUR_KEYVAULT_URI` with your Key Vault URI.

#### 3.2 Frontend Settings

Create a `.env` file in the frontend directory:

```
REACT_APP_API_URL=http://localhost:5000
```

### 4. Run the Application Locally

#### Using Docker Compose

```powershell
docker-compose up --build
```

The application will be available at:
- Frontend: http://localhost:3000
- Backend API: http://localhost:5000

### 5. Deploy to Azure Container Apps

You can use the GitHub Actions workflow to deploy the application to Azure Container Apps. You need to set up the following secrets in your GitHub repository:

- `AZURE_CREDENTIALS`: Service principal credentials for Azure
- `ACR_USERNAME`: Your ACR username
- `ACR_PASSWORD`: Your ACR password
- `AZURE_OPENAI_ENDPOINT`: Your Azure OpenAI endpoint
- `KEYVAULT_URI`: Your Key Vault URI

The workflow will build and push the Docker images to ACR and deploy them to Azure Container Apps.

#### Manual Deployment

Alternatively, you can deploy manually using Azure CLI:

```powershell
# Build and push backend image
docker build -t $acrName.azurecr.io/chatbot-backend:latest ./backend
docker push $acrName.azurecr.io/chatbot-backend:latest

# Build and push frontend image
docker build -t $acrName.azurecr.io/chatbot-frontend:latest ./frontend
docker push $acrName.azurecr.io/chatbot-frontend:latest

# Create Container Apps Environment
$envName = "containerapp-env"
az containerapp env create --name $envName --resource-group $resourceGroup --location $location

# Create backend Container App
az containerapp create --name "ca-chatbotai-backend-dev" --resource-group $resourceGroup --environment $envName --image "$acrName.azurecr.io/chatbot-backend:latest" --target-port 80 --ingress external --registry-server "$acrName.azurecr.io" --registry-username $acrUsername --registry-password $acrPassword --env-vars "AzureOpenAI__Endpoint=$openaiEndpoint" "KeyVault__Uri=$keyvaultUri"

# Get backend URL
$backendFqdn = az containerapp show --name "ca-chatbotai-backend-dev" --resource-group $resourceGroup --query properties.configuration.ingress.fqdn -o tsv

# Create frontend Container App
az containerapp create --name "ca-chatbotai-frontend-dev" --resource-group $resourceGroup --environment $envName --image "$acrName.azurecr.io/chatbot-frontend:latest" --target-port 80 --ingress external --registry-server "$acrName.azurecr.io" --registry-username $acrUsername --registry-password $acrPassword --env-vars "REACT_APP_API_URL=https://$backendFqdn"

# Update CORS settings on backend
$frontendFqdn = az containerapp show --name "ca-chatbotai-frontend-dev" --resource-group $resourceGroup --query properties.configuration.ingress.fqdn -o tsv
az containerapp update --name "ca-chatbotai-backend-dev" --resource-group $resourceGroup --set-env-vars "ALLOWED_ORIGINS=https://$frontendFqdn,http://localhost:3000"

# Get application URLs
$backendUrl = "https://$backendFqdn"
$frontendUrl = "https://$frontendFqdn"

Write-Host "Backend URL: $backendUrl"
Write-Host "Frontend URL: $frontendUrl"
```

## Project Structure

- `/backend`: .NET 8 API that communicates with Azure OpenAI
- `/frontend`: React TypeScript application for the chat interface
- `/.github`: GitHub Actions workflow files for CI/CD
- `/docker-compose.yml`: Configuration for local development

## Technologies Used

- **Backend**: .NET 8, Azure OpenAI SDK, Azure Identity
- **Frontend**: React, TypeScript, Axios
- **Deployment**: Docker, Azure Container Apps, GitHub Actions
- **Azure Services**: Azure OpenAI, Azure Container Registry, Azure Key Vault, Azure Container Apps
