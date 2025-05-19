// Core cluster configuration
@description('The name of the AKS cluster')
param clusterName string = 'aks-chatbotAI'

@description('The Azure region for the deployment')
param location string = resourceGroup().location

@description('The AKS environment (dev, test, prod)')
@allowed([
  'dev'
  'test'
  'prod'
])
param environment string = 'dev'

// Node pool configuration
@description('The number of nodes for the default node pool')
@minValue(1)
@maxValue(50)
param nodeCount int = 1

@description('The size of the Virtual Machine for the nodes')
param vmSize string = 'standard_d2s_v3'

// SSH configuration - required by AKS for Linux nodes
@description('Username for the Linux nodes admin account')
param adminUsername string = 'aksadmin'

@description('SSH RSA public key for the Linux nodes')
@secure()
param sshPublicKey string

// Tags for better resource management
var tags = {
  environment: environment
  application: 'chatbotAI'
  deploymentType: 'Bicep'
}

// AKS cluster definition
resource aksCluster 'Microsoft.ContainerService/managedClusters@2023-10-01' = {
  name: clusterName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    dnsPrefix: '${clusterName}-dns'
    enableRBAC: true
    agentPoolProfiles: [
      {
        name: 'agentpool'
        count: nodeCount
        vmSize: vmSize
        osType: 'Linux'
        mode: 'System'
        osDiskSizeGB: 0 // Use default OS disk size for the VM size
      }
    ]
    linuxProfile: {
      adminUsername: adminUsername
      ssh: {
        publicKeys: [
          {
            keyData: sshPublicKey
          }
        ]
      }
    }
  }
}

// Outputs
output controlPlane string = aksCluster.properties.fqdn
output kubeId string = aksCluster.id
output kubeName string = aksCluster.name
