// ChatbotAI Infrastructure Definition

// PARAMETERS

// Base parameters
@description('The name prefix for all resources')
param appNamePrefix string = 'chatbot'

@description('Environment name (dev, test, prod)')
@allowed([
  'dev'
  'test'
  'prod'
])
param environmentName string = 'dev'

@description('Location for all resources')
param location string = resourceGroup().location

// Resource-specific parameters
@description('Name of the GPT model to use')
param openAiModelName string = 'gpt-4o-mini'

@description('SKU for the Azure OpenAI resource')
param openAiSku string = 'S0'

@description('Number of nodes in the AKS cluster')
@minValue(1)
@maxValue(10)
param aksNodeCount int = 2

@description('VM size for the AKS nodes')
param aksVmSize string = 'Standard_D4ps_v6'

// VARIABLES

// Define naming convention for resources
var sanitizedAppName = replace(toLower(appNamePrefix), ' ', '')
var sanitizedEnv = toLower(environmentName)
var resourceSuffix = '${sanitizedAppName}-${sanitizedEnv}'
var uniqueSuffix = uniqueString(resourceGroup().id)

// Resource names based on naming convention
var acrName = 'acr${sanitizedAppName}${sanitizedEnv}${uniqueSuffix}'
var keyVaultName = 'kv-${resourceSuffix}-${uniqueSuffix}'
var aksClusterName = 'aks-${resourceSuffix}'
var openAiName = 'oai-${resourceSuffix}'
var openAiDeploymentName = 'gpt4mini-${sanitizedEnv}'
var logAnalyticsName = 'log-${resourceSuffix}'
var userAssignedIdentityName = 'id-${resourceSuffix}'
var appInsightsName = 'ai-${resourceSuffix}'

// RESOURCES

// Log Analytics Workspace (for monitoring)
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// Application Insights
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
  }
}

// User-assigned Managed Identity (for service connections)
resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: userAssignedIdentityName
  location: location
}

// Azure Container Registry
resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  sku: {
    name: 'Standard'  // Using Standard for better performance and storage
  }
  properties: {
    adminUserEnabled: true  // Enable admin for initial setup simplicity
  }
}

// Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true  // Use RBAC for access control
    enabledForDeployment: true
    enabledForTemplateDeployment: true
  }
}

// AKS Cluster with Monitor and ACR integration
resource aks 'Microsoft.ContainerService/managedClusters@2023-10-01' = {
  name: aksClusterName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentity.id}': {}
    }
  }
  properties: {
    dnsPrefix: '${aksClusterName}-dns'
    agentPoolProfiles: [
      {
        name: 'nodepool1'
        count: aksNodeCount
        vmSize: aksVmSize
        osType: 'Linux'
        mode: 'System'
        enableAutoScaling: true
        minCount: 1
        maxCount: aksNodeCount + 1
      }
    ]
    addonProfiles: {
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: logAnalytics.id
        }
      }
      azureKeyvaultSecretsProvider: {
        enabled: true
      }
    }
    ingressProfile: {
      webAppRouting: {
        enabled: true
      }
    }
  }
}

// Azure OpenAI Service
resource openAi 'Microsoft.CognitiveServices/accounts@2023-10-01-preview' = {
  name: openAiName
  location: location
  sku: {
    name: openAiSku
  }
  kind: 'OpenAI'
  properties: {
    networkAcls: {
      defaultAction: 'Allow'
    }
    publicNetworkAccess: 'Enabled'
  }
}

// OpenAI Model Deployment
resource openAiDeployment 'Microsoft.CognitiveServices/accounts/deployments@2023-10-01-preview' = {
  parent: openAi
  name: openAiDeploymentName
  sku: {
    name: 'Standard'
    capacity: 1
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: openAiModelName
    }
  }
}

// ROLE ASSIGNMENTS

// Give AKS identity ACR pull access
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, userAssignedIdentity.id, 'acrpull')
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d') // AcrPull role
    principalId: userAssignedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// Give AKS identity Key Vault Secrets User access
resource kvSecretsUserRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, userAssignedIdentity.id, 'secretsuser')
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6') // Key Vault Secrets User role
    principalId: userAssignedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// Give AKS identity Cognitive Services User role to access OpenAI
resource openAiUserRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(openAi.id, userAssignedIdentity.id, 'oaiuser')
  scope: openAi
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'a97b65f3-24c7-4388-baec-2e87135dc908') // Cognitive Services User
    principalId: userAssignedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// SECRETS

// Store OpenAI key in Key Vault
resource openAiKeySecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'OpenAiApiKey'
  properties: {
    value: openAi.listKeys().key1
  }
}

// Store OpenAI endpoint in Key Vault
resource openAiEndpointSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'OpenAiEndpoint'
  properties: {
    value: openAi.properties.endpoint
  }
}

// Store ACR admin credentials in Key Vault
resource acrUsernameSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'AcrUsername'
  properties: {
    value: acr.listCredentials().username
  }
}

resource acrPasswordSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'AcrPassword'
  properties: {
    value: acr.listCredentials().passwords[0].value
  }
}

// Store Application Insights key in Key Vault
resource appInsightsKeySecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'ApplicationInsightsKey'
  properties: {
    value: appInsights.properties.InstrumentationKey
  }
}

// OUTPUTS
output acrName string = acr.name
output acrLoginServer string = acr.properties.loginServer
output aksClusterName string = aks.name
output keyVaultName string = keyVault.name
output openAiName string = openAi.name
output openAiDeploymentName string = openAiDeployment.name
output openAiEndpoint string = openAi.properties.endpoint
output appInsightsInstrumentationKey string = appInsights.properties.InstrumentationKey
output userAssignedIdentityId string = userAssignedIdentity.id
output userAssignedIdentityClientId string = userAssignedIdentity.properties.clientId
output resourceGroupName string = resourceGroup().name




