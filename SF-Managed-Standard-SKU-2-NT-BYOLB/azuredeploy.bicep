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
param nodeType1Name string = 'NT1'
param nodeType1VmSize string = 'Standard_D2s_v3'
param nodeType1VmInstanceCount int = 5
param nodeType1DataDiskSizeGB int = 256

@allowed([
  'Standard_LRS'
  'StandardSSD_LRS'
  'Premium_LRS'
])
param nodeType1managedDataDiskType string = 'StandardSSD_LRS'

@maxLength(9)
param nodeType2Name string = 'NT2'
param nodeType2VmSize string = 'Standard_D2s_v3'
param nodeType2VmInstanceCount int = 3
param nodeType2DataDiskSizeGB int = 128

@allowed([
  'Standard_LRS'
  'StandardSSD_LRS'
  'Premium_LRS'
])
param nodeType2managedDataDiskType string = 'StandardSSD_LRS'
param vmImagePublisher string = 'MicrosoftWindowsServer'
param vmImageOffer string = 'WindowsServer'
param vmImageSku string = '2019-Datacenter'
param vmImageVersion string = 'latest'

@description('Resource ID of the Load Balancer backend pool that the VMSS of the node type is deployed to. Should be in the format of \'/subscriptions/<SubscriptionId>/resourceGroups/<ResourceGroupName>/providers/Microsoft.Network/loadBalancers/<LoadBalancerName>/backendAddressPools/<BackendPoolName>\'.')
param publicLoadBalancerBackendPoolId string

@description('Resource ID of the Load Balancer inbound NAT pool that the VMSS of the node type is deployed to. Should be in the format of \'/subscriptions/<SubscriptionId>/resourceGroups/<ResourceGroupName>/providers/Microsoft.Network/loadBalancers/<LoadBalancerName>/inboundNatPools/<NATPoolName>\'.')
param publicLoadBalancerNatPoolId string

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
    dataDiskType: nodeType1managedDataDiskType
  }
}

resource clusterName_nodeType2 'Microsoft.ServiceFabric/managedclusters/nodetypes@2022-08-01-preview' = {
  parent: cluster
  name: '${nodeType2Name}'
  properties: {
    isPrimary: false
    vmImagePublisher: vmImagePublisher
    vmImageOffer: vmImageOffer
    vmImageSku: vmImageSku
    vmImageVersion: vmImageVersion
    vmSize: nodeType2VmSize
    vmInstanceCount: nodeType2VmInstanceCount
    dataDiskSizeGB: nodeType2DataDiskSizeGB
    dataDiskType: nodeType2managedDataDiskType
    frontendConfigurations: [
      {
        loadBalancerBackendAddressPoolId: publicLoadBalancerBackendPoolId
        loadBalancerInboundNatPoolId: publicLoadBalancerNatPoolId
      }
    ]
    networkSecurityRules: [
      {
        name: 'AllowAppPort8000'
        protocol: '*'
        sourcePortRange: '*'
        sourceAddressPrefix: '*'
        destinationAddressPrefix: 'VirtualNetwork'
        destinationPortRange: '8080'
        access: 'Allow'
        priority: 2005
        direction: 'Inbound'
        description: 'Allow inbound communication to application port 8080.'
      }
    ]
  }
}

output serviceFabricExplorer string = 'https://${cluster.properties.fqdn}:${cluster.properties.httpGatewayConnectionPort}'
output clientConnectionEndpoint string = '${cluster.properties.fqdn}:${cluster.properties.clientConnectionPort}'
output clusterProperties object = cluster.properties
