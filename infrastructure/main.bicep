targetScope = 'subscription'

param rgName string = 'rg-chatbotAI'
param location string = 'westeurope'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: rgName
  location: location
  tags: {
    purpose: 'chatbot'
    environment: 'development'
  }
}

output resourceGroupId string = resourceGroup.id
output resourceGroupName string = resourceGroup.name


 