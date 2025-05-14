#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Updates Kubernetes manifests with the correct image references from ACR.
.DESCRIPTION
    This script updates the Kubernetes kustomization.yaml file with the correct ACR image paths
    after the infrastructure has been deployed.
.PARAMETER ResourceGroupName
    The name of the resource group containing the ACR.
.PARAMETER AcrName
    The name of the Azure Container Registry.
.EXAMPLE
    ./update-k8s-manifests.ps1 -ResourceGroupName "rg-chatbot-dev" -AcrName "acrchatbotdev123abc"
#>

param (
    [Parameter(Mandatory = $true)]
    [string] $ResourceGroupName,
    
    [Parameter(Mandatory = $false)]
    [string] $AcrName = ""
)

# Set error action preference
$ErrorActionPreference = "Stop"

# If AcrName is not provided, try to find it in the resource group
if (-not $AcrName) {
    Write-Host "ACR name not provided, attempting to find it in resource group $ResourceGroupName..." -ForegroundColor Yellow
    $acr = az acr list --resource-group $ResourceGroupName --query "[0].name" --output tsv
    if (-not $acr) {
        Write-Host "No ACR found in resource group $ResourceGroupName. Please provide the ACR name explicitly." -ForegroundColor Red
        exit 1
    }
    $AcrName = $acr
}

# Get ACR login server
Write-Host "Getting login server for ACR $AcrName..." -ForegroundColor Blue
$acrLoginServer = az acr show --name $AcrName --resource-group $ResourceGroupName --query "loginServer" --output tsv

if (-not $acrLoginServer) {
    Write-Host "Could not find ACR $AcrName in resource group $ResourceGroupName." -ForegroundColor Red
    exit 1
}

Write-Host "Found ACR login server: $acrLoginServer" -ForegroundColor Green

# Check if kubernetes/kustomization.yaml exists
$kustomizationPath = "../kubernetes/kustomization.yaml"
if (-not (Test-Path $kustomizationPath)) {
    Write-Host "Kustomization file not found at $kustomizationPath" -ForegroundColor Red
    exit 1
}

# Read current kustomization file
$content = Get-Content $kustomizationPath -Raw

# Create backup
$backupPath = "$kustomizationPath.bak"
Write-Host "Creating backup of kustomization.yaml at $backupPath" -ForegroundColor Yellow
Copy-Item $kustomizationPath $backupPath -Force

# Update image references
$updatedContent = $content -replace "acrdemopn.azurecr.io/chatbot-backend", "$acrLoginServer/chatbot-backend"
$updatedContent = $updatedContent -replace "acrdemopn.azurecr.io/chatbot-frontend", "$acrLoginServer/chatbot-frontend"

# Write updated content
Write-Host "Updating kustomization.yaml with new ACR path: $acrLoginServer" -ForegroundColor Blue
Set-Content -Path $kustomizationPath -Value $updatedContent

Write-Host "Kubernetes manifests have been updated successfully." -ForegroundColor Green
Write-Host "`nYou can now deploy to Kubernetes with:" -ForegroundColor Yellow
Write-Host "kubectl apply -k ./kubernetes/" -ForegroundColor Cyan
