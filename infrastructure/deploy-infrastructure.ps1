#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Deploys the ChatbotAI infrastructure to Azure using Bicep templates.
.DESCRIPTION
    This script creates a new resource group and deploys all necessary Azure resources
    for running the ChatbotAI application, including AKS, ACR, Key Vault, and Azure OpenAI.
.PARAMETER ResourceGroupName
    The name of the resource group to create and deploy resources into.
.PARAMETER Location
    The Azure region where resources should be deployed.
.PARAMETER EnvironmentName
    The environment name (dev, test, or prod).
.EXAMPLE
    ./deploy-infrastructure.ps1 -ResourceGroupName "rg-chatbot-demo" -Location "eastus" -EnvironmentName "dev"
#>

param (
    [Parameter(Mandatory = $true)]
    [string] $ResourceGroupName,
    
    [Parameter(Mandatory = $false)]
    [string] $Location = "westeurope",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("dev", "test", "prod")]
    [string] $EnvironmentName = "dev"
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Ensure user is logged in
Write-Host "Checking Azure login status..." -ForegroundColor Blue
$loginStatus = az account show --output json | ConvertFrom-Json -ErrorAction SilentlyContinue
if (-not $loginStatus) {
    Write-Host "You need to login to Azure first. Running 'az login'..." -ForegroundColor Yellow
    az login
}

# Get/Set subscription
$subscription = az account show --output json | ConvertFrom-Json
Write-Host "Using subscription: $($subscription.name)" -ForegroundColor Green

# Create resource group if it doesn't exist
Write-Host "Creating resource group '$ResourceGroupName' in location '$Location' if it doesn't exist..." -ForegroundColor Blue
az group create --name $ResourceGroupName --location $Location

# Deploy Bicep template
Write-Host "Deploying infrastructure using Bicep template..." -ForegroundColor Blue
$deployment = az deployment group create `
    --resource-group $ResourceGroupName `
    --template-file "./infra.bicep" `
    --parameters "./infra.parameters.json" `
    --parameters environmentName=$EnvironmentName `
    --output json | ConvertFrom-Json

if ($LASTEXITCODE -ne 0) {
    Write-Host "Deployment failed. Check the error message above." -ForegroundColor Red
    exit 1
}

# Extract key outputs
$outputs = $deployment.properties.outputs
$acrName = $outputs.acrName.value
$acrLoginServer = $outputs.acrLoginServer.value
$aksClusterName = $outputs.aksClusterName.value
$keyVaultName = $outputs.keyVaultName.value
$openAiName = $outputs.openAiName.value

# Display output information
Write-Host "`n==================== DEPLOYMENT SUCCESSFUL ====================`n" -ForegroundColor Green
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor White
Write-Host "ACR: $acrName ($acrLoginServer)" -ForegroundColor White
Write-Host "AKS Cluster: $aksClusterName" -ForegroundColor White
Write-Host "Key Vault: $keyVaultName" -ForegroundColor White
Write-Host "OpenAI Service: $openAiName" -ForegroundColor White

# Log into ACR
Write-Host "`nConnecting to AKS cluster..." -ForegroundColor Blue
az aks get-credentials --resource-group $ResourceGroupName --name $aksClusterName --overwrite-existing

Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Build and push your Docker images to ACR:" -ForegroundColor White
Write-Host "   az acr login --name $acrName" -ForegroundColor Cyan
Write-Host "   docker build -t $acrLoginServer/chatbot-backend:latest -f ./backend/Dockerfile ./backend" -ForegroundColor Cyan
Write-Host "   docker build -t $acrLoginServer/chatbot-frontend:latest -f ./frontend/Dockerfile ./frontend" -ForegroundColor Cyan
Write-Host "   docker push $acrLoginServer/chatbot-backend:latest" -ForegroundColor Cyan
Write-Host "   docker push $acrLoginServer/chatbot-frontend:latest" -ForegroundColor Cyan

Write-Host "`n2. Update your Kubernetes manifests with the correct image names" -ForegroundColor White
Write-Host "   Update 'kubernetes/kustomization.yaml' with the new image paths: $acrLoginServer/chatbot-backend and $acrLoginServer/chatbot-frontend" -ForegroundColor Cyan

Write-Host "`n3. Deploy to Kubernetes:" -ForegroundColor White
Write-Host "   kubectl apply -k ./kubernetes/" -ForegroundColor Cyan

Write-Host "`n4. Get the external IP address of your Ingress:" -ForegroundColor White
Write-Host "   kubectl get ingress chatbot-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}'" -ForegroundColor Cyan

Write-Host "`nCommon troubleshooting commands:" -ForegroundColor Yellow
Write-Host "   kubectl get pods" -ForegroundColor Cyan
Write-Host "   kubectl describe pod [pod-name]" -ForegroundColor Cyan
Write-Host "   kubectl logs [pod-name]" -ForegroundColor Cyan
Write-Host "   kubectl get events --sort-by='.lastTimestamp'" -ForegroundColor Cyan
