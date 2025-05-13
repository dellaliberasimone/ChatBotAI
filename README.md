# Swagger Minimal API with Azure OpenAI

A minimal API implementation using .NET 9.0 that integrates with Azure OpenAI services. The API provides a simple endpoint for chat completions using GPT models.

## Architecture Diagram

![Architecture Diagram](images/architecture-diagram.png)

## Features

- Minimal API architecture with .NET 9.0
- Azure OpenAI integration
- Swagger UI integration
- Kubernetes deployment ready
- GitHub Actions CI/CD pipeline
- Support for Azure Key Vault secrets management
- Managed Identity authentication

## Prerequisites

- .NET 8.0 SDK
- Docker with ARM64 support
- Azure subscription with:
  - Azure OpenAI service
  - Azure Container Registry
  - Azure Kubernetes Service (for deployment)
  - Azure Key Vault (optional, for secrets management)

## Local Development

1. Clone the repository
2. Configure your Azure OpenAI settings in `appsettings.json` or user secrets
3. Run the application:
   ```
   dotnet run
   ```

## Deployment

The application includes a complete CI/CD pipeline using GitHub Actions that:
- Builds and tests the application
- Creates a Docker container
- Pushes to Azure Container Registry
- Deploys to AKS

## Architecture

The application uses a flexible authentication approach:
1. Primary: Azure Key Vault with Managed Identity
2. Secondary: Direct API Key configuration
3. Fallback: Direct Managed Identity authentication with Azure OpenAI

## API Endpoints

- GET `/`: Health check endpoint
- POST `/openai`: Chat completion endpoint
  - Requires a JSON body with a `prompt` field
  - Returns the AI assistant's response.