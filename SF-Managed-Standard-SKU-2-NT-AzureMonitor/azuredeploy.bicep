@secure()
param adminPassword string = ''
param adminUserName string = ''
param clientCertificateThumbprint string = ''
param clusterName string = ''
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

resource cluster 'Microsoft.ServiceFabric/managedClusters@2022-01-01' = {
  name: clusterName
  location: resourceGroup().location
  sku: {
    name: 'Standard'
  }
  properties: {
    clusterUpgradeMode: 'Automatic'
    clusterUpgradeCadence: 'Wave0'
    adminUserName: adminUserName
    adminPassword: adminPassword
    dnsName: clusterName
    clientConnectionPort: 19000
    httpGatewayConnectionPort: 19080
    allowRdpAccess: false
    clients: [
      {
        isAdmin: true
        thumbprint: clientCertificateThumbprint
      }
    ]
    addonFeatures: [
      'DnsService'
    ]
    enableAutoOSUpgrade: false
    zonalResiliency: true
  }
}

resource clusterName_nodeType1 'Microsoft.ServiceFabric/managedClusters/nodetypes@2022-01-01' = {
  parent: cluster
  name: '${nodeType1Name}'
  properties: {
    isPrimary: true
    vmImagePublisher: 'MicrosoftWindowsServer'
    vmImageOffer: 'WindowsServer'
    vmImageSku: '2019-Datacenter'
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
        name: 'AzureMonitorWindowsAgent-${nodeType1Name}'
        properties: {
          publisher: 'Microsoft.Azure.Monitor'
          type: 'AzureMonitorWindowsAgent'
          typeHandlerVersion: '1.2'
          autoUpgradeMinorVersion: true
          enableAutomaticUpgrade: true
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
  name: '${nodeType2Name}'
  properties: {
    isPrimary: false
    vmImagePublisher: 'MicrosoftWindowsServer'
    vmImageOffer: 'WindowsServer'
    vmImageSku: '2019-Datacenter'
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
        name: 'AzureMonitorWindowsAgent-${nodeType2Name}'
        properties: {
          publisher: 'Microsoft.Azure.Monitor'
          type: 'AzureMonitorWindowsAgent'
          typeHandlerVersion: '1.2'
          autoUpgradeMinorVersion: true
          enableAutomaticUpgrade: true
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
