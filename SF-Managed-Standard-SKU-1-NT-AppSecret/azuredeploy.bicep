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
param nodeType1Name string = 'NT1'
param nodeType1VmSize string = 'Standard_D2s_v3'
param nodeType1VmInstanceCount int = 5
param nodeType1DataDiskSizeGB int = 256
param vmImagePublisher string = 'MicrosoftWindowsServer'
param vmImageOffer string = 'WindowsServer'
param vmImageSku string = '2019-Datacenter'
param vmImageVersion string = 'latest'

@allowed([
  'Standard_LRS'
  'StandardSSD_LRS'
  'Premium_LRS'
])
param managedDataDiskType string = 'StandardSSD_LRS'
param sourceVaultValue string
param certificate1UrlValue string

resource cluster 'Microsoft.ServiceFabric/managedclusters@2022-08-01-preview' = {
  name: clusterName
  location: resourceGroup().location
  sku: {
    name: clusterSku
  }
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
    loadBalancingRules: [
      {
        frontendPort: 8080
        backendPort: 8080
        protocol: 'tcp'
        probeProtocol: 'tcp'
      }
    ]
  }
}

resource clusterName_nodeType1 'Microsoft.ServiceFabric/managedclusters/nodetypes@2022-08-01-preview' = {
  parent: cluster
  name: '${nodeType1Name}'
  properties: {
    isPrimary: true
    vmImagePublisher: vmImagePublisher
    vmImageOffer: vmImageOffer
    vmImageSku: vmImageSku
    vmImageVersion: vmImageVersion
    vmSize: nodeType1VmSize
    vmInstanceCount: nodeType1VmInstanceCount
    dataDiskSizeGB: nodeType1DataDiskSizeGB
    dataDiskType: managedDataDiskType
    vmSecrets: [
      {
        sourceVault: {
          id: sourceVaultValue
        }
        vaultCertificates: [
          {
            certificateStore: 'My'
            certificateUrl: certificate1UrlValue
          }
        ]
      }
    ]
  }
}

output serviceFabricExplorer string = 'https://${cluster.properties.fqdn}:${cluster.properties.httpGatewayConnectionPort}'
output clientConnectionEndpoint string = '${cluster.properties.fqdn}:${cluster.properties.clientConnectionPort}'
output clusterProperties object = cluster.properties
