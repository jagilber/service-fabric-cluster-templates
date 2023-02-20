param clusterName string
param clusterLocation string = resourceGroup().location
param adminUserName string = 'vmadmin'

@secure()
param adminPassword string
param vmImagePublisher string = 'MicrosoftWindowsServer'
param vmImageOffer string = 'WindowsServer'
param vmImageSku string = '2019-Datacenter'
param vmImageVersion string = 'latest'
param nodeTypeName string
param nodeTypeName2 string
param vmSize string = 'Standard_D2s_v3'
param vmInstanceCount int = 6
param dataDiskSizeGB int = 120
param clientThumbprint string
param hostGroupId string
param zone string = '1'

resource cluster 'Microsoft.ServiceFabric/managedclusters@2022-08-01-preview' = {
  name: clusterName
  location: clusterLocation
  sku: {
    name: 'Standard'
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
        thumbprint: clientThumbprint
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
    hostGroupId: hostGroupId
    zones: [
      zone
    ]
    enableEncryptionAtHost: true
  }
}

resource clusterName_nodeType2 'Microsoft.ServiceFabric/managedclusters/nodetypes@2022-08-01-preview' = {
  parent: cluster
  name: '${nodeTypeName2}'
  properties: {
    isPrimary: false
    vmImagePublisher: vmImagePublisher
    vmImageOffer: vmImageOffer
    vmImageSku: vmImageSku
    vmImageVersion: vmImageVersion
    vmSize: vmSize
    vmInstanceCount: vmInstanceCount
    dataDiskSizeGB: dataDiskSizeGB
    hostGroupId: hostGroupId
    zones: [
      zone
    ]
    enableEncryptionAtHost: true
  }
}

output clusterProperties object = cluster.properties
