# ChatbotAI - Intelligent Chat Application

A modern chat application using React for the frontend and a .NET minimal API for the backend, powered by Azure OpenAI services. The application provides a sleek chat interface that connects to Azure OpenAI for intelligent responses.

## Architecture Diagram

![Architecture Diagram](images/architecture-diagram.png)

## Features

- Modern React frontend with a beautiful chat UI
- Minimal API backend with .NET 8.0
- Azure OpenAI integration with GPT models
- Real-time chat experience with typing indicators
- Kubernetes deployment ready
- GitHub Actions CI/CD pipeline
- Docker and Docker Compose support
- Support for Azure Key Vault secrets management
- Managed Identity authentication

## Prerequisites

- .NET 8.0 SDK
- Node.js 14+
- Docker and Docker Compose
- Azure subscription with:
  - Azure OpenAI service
  - Azure Container Registry
  - Azure Kubernetes Service (for deployment)
  - Azure Key Vault (optional, for secrets management)

## Local Development

### Backend

1. Configure your Azure OpenAI settings in `backend/appsettings.json` or user secrets
2. Navigate to the backend directory:
   ```powershell
   cd backend
   ```
3. Run the backend application:
   ```powershell
   dotnet run
   ```

### Frontend

1. Create a `.env` file in the frontend directory with:
   ```
   REACT_APP_API_URL=http://localhost:5000
   ```
2. Navigate to the frontend directory:
   ```powershell
   cd frontend
   ```
3. Install dependencies:
   ```powershell
   npm install
   ```
4. Run the frontend application:
   ```powershell
   npm start
   ```

### Using Docker Compose

To run both the frontend and backend together:

```powershell
docker-compose up
```

## Deployment

The application includes a complete CI/CD pipeline using GitHub Actions that:
- Builds and tests the application
- Creates a Docker container
- Pushes to Azure Container Registry
- Deploys to AKS

## Project Structure

### Backend

- `backend/`: .NET minimal API backend
  - `Program.cs`: Main application entry point with API endpoints
  - `chatbot-backend.csproj`: Project file
  - `appsettings.json`: Configuration settings

### Frontend

- `frontend/`: React frontend application
  - `src/components/`: React components
    - `Chat.tsx`: Main chat container component
    - `MessageComponent.tsx`: Individual message component
  - `src/services/`: API services
    - `chatService.ts`: Service for communicating with backend
  - `src/types/`: TypeScript type definitions

### Infrastructure

- `infrastructure/`: Docker and infrastructure files
  - `Dockerfile`: Backend Docker configuration
  - `infra.bicep`: Azure infrastructure as code
- `kubernetes/`: Kubernetes deployment files
  - `k8s-deployment.yaml`: Kubernetes deployment configuration
  - `kustomization.yaml`: Kustomize configuration

## Authentication Architecture

The backend application uses a flexible authentication approach:
1. Primary: Azure Key Vault with Managed Identity
2. Secondary: Direct API Key configuration
3. Fallback: Direct Managed Identity authentication with Azure OpenAI

## API Endpoints

- GET `/`: Health check endpoint
- POST `/api/chat`: Chat completion endpoint
  - Requires a JSON body with a `message` field
  - Returns the AI assistant's response as a ChatResponse object:
    ```json
    {
      "text": "The AI response text",
      "type": "bot"
    }
    ```