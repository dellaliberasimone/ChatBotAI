# This script rebuilds the Docker images with the correct platform and deploys them to AKS
param (
    [Parameter(Mandatory = $false)]
    [string] $AcrName = "acrdemopn"
)

$ErrorActionPreference = "Stop"

# Ensure user is logged in
Write-Host "Checking Azure login status..." -ForegroundColor Blue
$loginStatus = az account show --output json | ConvertFrom-Json -ErrorAction SilentlyContinue
if (-not $loginStatus) {
    Write-Host "You need to login to Azure first. Running 'az login'..." -ForegroundColor Yellow
    az login
}

# Log into ACR
Write-Host "Logging into ACR..." -ForegroundColor Blue
az acr login --name $AcrName

$acrLoginServer = "$AcrName.azurecr.io"

# Build and push the Docker images with platform specified
Write-Host "Building and pushing backend Docker image with linux/amd64 platform..." -ForegroundColor Blue
docker build --platform linux/amd64 -t "$acrLoginServer/chatbot-backend:latest" -f ./backend/Dockerfile ./backend
if ($LASTEXITCODE -ne 0) {
    Write-Host "Backend Docker build failed." -ForegroundColor Red
    exit 1
}

docker push "$acrLoginServer/chatbot-backend:latest"
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to push backend Docker image to ACR." -ForegroundColor Red
    exit 1
}

Write-Host "Building and pushing frontend Docker image with linux/amd64 platform..." -ForegroundColor Blue
docker build --platform linux/amd64 -t "$acrLoginServer/chatbot-frontend:latest" -f ./frontend/Dockerfile ./frontend
if ($LASTEXITCODE -ne 0) {
    Write-Host "Frontend Docker build failed." -ForegroundColor Red
    exit 1
}

docker push "$acrLoginServer/chatbot-frontend:latest"
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to push frontend Docker image to ACR." -ForegroundColor Red
    exit 1
}

# Restart the deployments to pick up the new images
Write-Host "Restarting the deployments..." -ForegroundColor Blue
kubectl rollout restart deployment chatbot-backend
kubectl rollout restart deployment chatbot-frontend

Write-Host "Waiting for rollout to complete..." -ForegroundColor Blue
kubectl rollout status deployment chatbot-backend
kubectl rollout status deployment chatbot-frontend

Write-Host "Deployment complete! Check the status of your pods:" -ForegroundColor Green
kubectl get pods
