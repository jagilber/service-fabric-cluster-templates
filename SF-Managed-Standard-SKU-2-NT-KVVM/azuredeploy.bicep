@description('Region')
param location string = resourceGroup().location

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
param nodeType1DataDiskSizeGB int = 256

@allowed([
  'Standard_LRS'
  'StandardSSD_LRS'
  'Premium_LRS'
])
param nodeType1managedDataDiskType string = 'StandardSSD_LRS'

@maxLength(9)
param nodeType1Name string = 'NT1'
param nodeType1VmInstanceCount int = 5
param nodeType1VmSize string = 'Standard_D2s_v3'
param nodeType2DataDiskSizeGB int = 128

@allowed([
  'Standard_LRS'
  'StandardSSD_LRS'
  'Premium_LRS'
])
param nodeType2managedDataDiskType string = 'StandardSSD_LRS'

@maxLength(9)
param nodeType2Name string = 'NT2'
param nodeType2VmInstanceCount int = 3
param nodeType2VmSize string = 'Standard_D2s_v3'

resource cluster 'Microsoft.ServiceFabric/managedclusters@2022-08-01-preview' = {
  name: clusterName
  location: location
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

resource clusterName_nodeType1 'Microsoft.ServiceFabric/managedclusters/nodetypes@2022-08-01-preview' = {
  parent: cluster
  name: nodeType1Name
  properties: {
    isPrimary: true
    vmImagePublisher: 'MicrosoftWindowsServer'
    vmImageOffer: 'WindowsServer'
    vmImageSku: '2022-Datacenter'
    vmImageVersion: 'latest'
    vmSize: nodeType1VmSize
    vmInstanceCount: nodeType1VmInstanceCount
    dataDiskSizeGB: nodeType1DataDiskSizeGB
    dataDiskType: nodeType1managedDataDiskType
    dataDiskLetter: 'S'
    placementProperties: {
    }
    capacities: {
    }
    applicationPorts: {
      startPort: 20000
      endPort: 30000
    }
    ephemeralPorts: {
      startPort: 49152
      endPort: 65534
    }
    vmSecrets: []
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
    isStateless: false
    multiplePlacementGroups: false
    enableEncryptionAtHost: false
    enableAcceleratedNetworking: false
    useTempDataDisk: false
  }
}

resource clusterName_nodeType2 'Microsoft.ServiceFabric/managedClusters/nodetypes@2022-01-01' = {
  parent: cluster
  name: nodeType2Name
  properties: {
    isPrimary: false
    vmImagePublisher: 'MicrosoftWindowsServer'
    vmImageOffer: 'WindowsServer'
    vmImageSku: '2022-Datacenter'
    vmImageVersion: 'latest'
    vmSize: nodeType2VmSize
    vmInstanceCount: nodeType2VmInstanceCount
    dataDiskSizeGB: nodeType2DataDiskSizeGB
    dataDiskType: nodeType2managedDataDiskType
    dataDiskLetter: 'S'
    placementProperties: {
    }
    capacities: {
    }
    applicationPorts: {
      startPort: 20000
      endPort: 30000
    }
    ephemeralPorts: {
      startPort: 49152
      endPort: 65534
    }
    vmSecrets: []
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
    isStateless: false
    multiplePlacementGroups: false
    enableEncryptionAtHost: false
    enableAcceleratedNetworking: false
    useTempDataDisk: false
  }
}

output serviceFabricExplorer string = 'https://${cluster.properties.fqdn}:${cluster.properties.httpGatewayConnectionPort}'
output clientConnectionEndpoint string = '${cluster.properties.fqdn}:${cluster.properties.clientConnectionPort}'
output clusterProperties object = cluster.properties
