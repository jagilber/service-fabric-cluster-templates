@description('Resource Group')
param location string = resourceGroup().location

@secure()
param adminPassword string = ''
param adminUserName string = ''
param clientCertificateThumbprint string = ''
param clusterName string = ''
param dataDiskSizeGB int = 256
param laWorkspaceId string = ''
param laWorkspaceKey string = ''
param vmInstanceCount int = 5
param vmSize string = ''

var nodeTypeName = 'nodetype1'

resource cluster 'Microsoft.ServiceFabric/managedClusters@2022-01-01' = {
  name: clusterName
  location: location
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

resource clusterName_nodeType 'Microsoft.ServiceFabric/managedClusters/nodetypes@2022-01-01' = {
  parent: cluster
  name: '${nodeTypeName}'
  properties: {
    isPrimary: true
    vmImagePublisher: 'MicrosoftWindowsServer'
    vmImageOffer: 'WindowsServer'
    vmImageSku: '2019-Datacenter'
    vmImageVersion: 'latest'
    vmSize: vmSize
    vmInstanceCount: vmInstanceCount
    dataDiskSizeGB: dataDiskSizeGB
    dataDiskType: 'StandardSSD_LRS'
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
        name: 'OMSExtension-${nodeTypeName}'
        properties: {
          publisher: 'Microsoft.EnterpriseCloud.Monitoring'
          type: 'MicrosoftMonitoringAgent'
          typeHandlerVersion: '1.0'
          autoUpgradeMinorVersion: true
          settings: {
            workspaceId: laWorkspaceId
          }
          protectedSettings: {
            workspaceKey: laWorkspaceKey
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
