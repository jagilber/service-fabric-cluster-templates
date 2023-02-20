@description('Resource Group')
param location string = resourceGroup().location

@description('Name of your cluster - Between 3 and 23 characters. Letters and numbers only')
@minLength(4)
@maxLength(23)
param clusterName string

@allowed([
  'Basic'
  'Standard'
])
param clusterSku string = 'Standard'
param adminUserName string = 'vmadmin'

@secure()
param adminPassword string
param clientCertificateThumbprint string

@maxLength(9)
param nodeTypeName string = 'NT1'
param vmImagePublisher string = 'MicrosoftWindowsServer'
param vmImageOffer string = 'WindowsServer'
param vmImageSku string = '2019-Datacenter'
param vmImageVersion string = 'latest'
param vmSize string = 'Standard_D2s_v3'
param vmInstanceCount int = 5
param dataDiskSizeGB int = 256

@allowed([
  'Standard_LRS'
  'StandardSSD_LRS'
  'Premium_LRS'
])
param managedDataDiskType string = 'StandardSSD_LRS'

@description('Full resource id of the Key Vault used for disk encryption.')
param keyVaultResourceId string

@description('Type of the volume OS or Data to perform encryption operation')
param volumeType string = 'All'

resource cluster 'Microsoft.ServiceFabric/managedclusters@2022-08-01-preview' = {
  name: clusterName
  sku: {
    name: clusterSku
  }
  location: location
  properties: {
    dnsName: toLower(clusterName)
    adminUserName: adminUserName
    adminPassword: adminPassword
    clientConnectionPort: 19000
    httpGatewayConnectionPort: 19080
    clients: [
      {
        isAdmin: true
        thumbprint: clientCertificateThumbprint
      }
    ]
  }
  dependsOn: []
}

resource clusterName_nodeType 'Microsoft.ServiceFabric/managedclusters/nodetypes@2022-08-01-preview' = {
  parent: cluster
  name: '${nodeTypeName}'
  properties: {
    isPrimary: true
    vmImagePublisher: vmImagePublisher
    vmImageOffer: vmImageOffer
    vmImageSku: vmImageSku
    vmImageVersion: vmImageVersion
    vmSize: vmSize
    vmInstanceCount: vmInstanceCount
    dataDiskSizeGB: dataDiskSizeGB
    dataDiskType: managedDataDiskType
    vmExtensions: [
      {
        name: 'AzureDiskEncryption'
        properties: {
          publisher: 'Microsoft.Azure.Security'
          type: 'AzureDiskEncryption'
          typeHandlerVersion: '2.1'
          autoUpgradeMinorVersion: true
          settings: {
            EncryptionOperation: 'EnableEncryption'
            KeyVaultURL: reference(keyVaultResourceId, '2016-10-01').vaultUri
            KeyVaultResourceId: keyVaultResourceId
            VolumeType: volumeType
          }
        }
      }
    ]
  }
}

output serviceFabricExplorer string = 'https://${cluster.properties.fqdn}:${cluster.properties.httpGatewayConnectionPort}'
output clientConnectionEndpoint string = '${cluster.properties.fqdn}:${cluster.properties.clientConnectionPort}'
output clusterProperties object = cluster.properties
