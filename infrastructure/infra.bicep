@description('Name of the Azure Container Registry')
param acrName string

@description('Name of the Azure Key Vault')
param keyVaultName string

@description('Name of the AKS Cluster')
param aksClusterName string

@description('Location for all resources')
param location string = resourceGroup().location

@description('Name of the Azure OpenAI resource')
param openAiName string

@description('Name of the GPT-4-mini deployment')
param openAiDeploymentName string

@description('SKU for the Azure OpenAI resource')
param openAiSku string = 'S0'

resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
    name: acrName
    location: location
    sku: {
        name: 'Basic'
    }
    properties: {
        adminUserEnabled: false
    }
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
    name: keyVaultName
    location: location
    properties: {
        sku: {
            family: 'A'
            name: 'standard'
        }
        tenantId: subscription().tenantId
        accessPolicies: []
    }
}

resource aks 'Microsoft.ContainerService/managedClusters@2023-01-01' = {
    name: aksClusterName
    location: location
    identity: {
        type: 'SystemAssigned'
    }
    properties: {
        dnsPrefix: '${aksClusterName}-dns'
        agentPoolProfiles: [
            {
                name: 'nodepool1'
                count: 2
                vmSize: 'Standard_DS2_v6'
                osType: 'Linux'
                mode: 'System'
            }
        ]
        servicePrincipalProfile: {
            clientId: 'msi'
        }
    }
}

resource openAi 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
    name: openAiName
    location: location
    sku: {
        name: openAiSku
    }
    kind: 'OpenAI'
    properties: {
        apiProperties: {
            openai: {
                deploymentName: openAiDeploymentName
                model: 'gpt-4o-mini'
            }
        }
    }
}




