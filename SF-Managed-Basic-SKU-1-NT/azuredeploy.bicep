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
param clusterSku string = 'Basic'
param adminUserName string = 'vmadmin'

@secure()
param adminPassword string

@description('Client Certificate Thumbprint')
param clientCertificateThumbprint string

@maxLength(9)
param nodeTypeName string = 'NT1'

param vmImagePublisher string = 'MicrosoftWindowsServer'
param vmImageOffer string = 'WindowsServer'
param vmImageSku string = '2019-Datacenter'
param vmImageVersion string = 'latest'
param vmSize string = 'Standard_D2s_v3'
param vmInstanceCount int = 3
param dataDiskSizeGB int = 128

@allowed([
  'Standard_LRS'
  'StandardSSD_LRS'
  'Premium_LRS'
])
param managedDataDiskType string = 'StandardSSD_LRS'

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
  #disable-next-line use-parent-property
  name: '${clusterName}/${nodeTypeName}'
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
  }
  dependsOn: [
    cluster
  ]
}

output serviceFabricExplorer string = 'https://${cluster.properties.fqdn}:${cluster.properties.httpGatewayConnectionPort}'
output clientConnectionEndpoint string = '${cluster.properties.fqdn}:${cluster.properties.clientConnectionPort}'
output clusterProperties object = cluster.properties
