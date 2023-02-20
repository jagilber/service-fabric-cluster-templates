@secure()
param adminPassword string
param adminUserName string = 'vmadmin'

#disable-next-line no-hardcoded-env-urls
@description('https://<vault name>.vault.azure.net/secrets/<certificate Name>')
param certificateUrls array
param clientCertificateThumbprint string

@description('Name of your cluster - Between 3 and 23 characters. Letters and numbers only')
@minLength(4)
@maxLength(23)
param clusterName string

@allowed([
  'Basic'
  'Standard'
])
param clusterSku string = 'Basic'
param dataDiskSizeGB int = 128

@allowed([
  'Standard_LRS'
  'StandardSSD_LRS'
  'Premium_LRS'
])
param managedDataDiskType string = 'StandardSSD_LRS'

@maxLength(9)
param nodeTypeName string = 'NT1'
param vmImageOffer string = 'WindowsServer'
param vmImagePublisher string = 'MicrosoftWindowsServer'
param vmImageSku string = '2022-Datacenter'
param vmImageVersion string = 'latest'
param vmInstanceCount int = 3
param vmSize string = 'Standard_D2s_v3'

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
    allowRdpAccess: false
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
        name: 'KVVMExtensionForWindows'
        properties: {
          publisher: 'Microsoft.Azure.KeyVault'
          type: 'KeyVaultForWindows'
          typeHandlerVersion: '1.0'
          autoUpgradeMinorVersion: true
          settings: {
            secretsManagementSettings: {
              pollingIntervalInS: '3600'
              certificateStoreName: 'MY'
              linkOnRenewal: false
              certificateStoreLocation: 'LocalMachine'
              requireInitialSync: false
              observedCertificates: certificateUrls
            }
          }
        }
      }
    ]
  }
}

output serviceFabricExplorer string = 'https://${cluster.properties.fqdn}:${cluster.properties.httpGatewayConnectionPort}'
output clientConnectionEndpoint string = '${cluster.properties.fqdn}:${cluster.properties.clientConnectionPort}'
output clusterProperties object = cluster.properties
