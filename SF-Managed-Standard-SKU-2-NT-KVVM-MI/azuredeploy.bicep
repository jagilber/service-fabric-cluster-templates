@description('Resource Group')
param location string = resourceGroup().location

@secure()
param adminPassword string
param adminUserName string = 'vmadmin'

@description('Specifies the permissions to certificates in the vault. Valid values are: all,  create, delete, update, deleteissuers, get, getissuers, import, list, listissuers, managecontacts, manageissuers,  recover, backup, restore, setissuers, and purge.')
@allowed([
  'all'
  'backup'
  'create'
  'delete'
  'deleteissuers'
  'get'
  'getissuers'
  'import'
  'list'
  'listissuers'
  'managecontacts'
  'manageissuers'
  'purge'
  'recover'
  'restore'
  'setissuers'
  'update'
])
param certificatePermissions array = [
  'list'
  'get'
]

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

@description('Specifies the permissions to keys in the vault. Valid values are: all, encrypt, decrypt, wrapKey, unwrapKey, sign, verify, get, list, create, update, import, delete, backup, restore, recover, and purge.')
@allowed([
  'all'
  'backup'
  'create'
  'decrypt'
  'delete'
  'encrypt'
  'get'
  'getrotationpolicy'
  'import'
  'list'
  'purge'
  'recover'
  'release'
  'restore'
  'rotate'
  'setrotationpolicy'
  'sign'
  'unwrapKey'
  'update'
  'verify'
  'wrapKey'
])
param keysPermissions array = [
  'list'
  'get'
]

@description('Optionally provide key vault resource id to update key vault access policy with user managed identity. format: /subscriptions/<subscription Id>/resourceGroups/<resource group>/providers/Microsoft.KeyVault/vaults/<vault name>')
param keyVaultResourceId string

@description('https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles')
param managedIdentityProviderGuid string = 'f1a07417-d97a-45cb-824c-7a7467783830'

@description('Specifies the permissions to secrets in the vault. Valid values are: all, get, list, set, delete, backup, restore, recover, and purge.')
@allowed([
  'all'
  'backup'
  'delete'
  'get'
  'list'
  'purge'
  'recover'
  'restore'
  'set'
])
param secretsPermissions array = [
  'list'
  'get'
]

@description('subscription specific. ps Get-AzADServicePrincipal -DisplayName \'Azure Service Fabric Resource Provider\'')
param sfrpProviderGuid string = ''
param userAssignedIdentityName string = '${resourceGroup().name}UserAssignedIdentity'

@description('ps [guid]::newguid() one time. https://docs.microsoft.com/en-us/azure/service-fabric/how-to-managed-identity-managed-cluster-virtual-machine-scale-sets')
param vmIdentityRoleNameGuid string = ''
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

var updateKeyvault = (length(keyVaultResourceId) > 0)
var kvIndexStart = (updateKeyvault ? (lastIndexOf(keyVaultResourceId, '/') + 1) : 0)
var kvIndexEnd = length(keyVaultResourceId)
var kvRgIndexStart = (updateKeyvault ? (indexOf(keyVaultResourceId, '/resourceGroups/') + 16) : 0)
var kvRgIndexEnd = (updateKeyvault ? indexOf(keyVaultResourceId, '/providers/') : 0)
var keyvaultName = substring(keyVaultResourceId, kvIndexStart, (kvIndexEnd - kvIndexStart))
var keyvaultResourceGroup = substring(keyVaultResourceId, kvRgIndexStart, (kvRgIndexEnd - kvRgIndexStart))
var kvSubIndexStart = (updateKeyvault ? (indexOf(keyVaultResourceId, '/subscriptions/') + 15) : 0)
var kvSubIndexEnd = (updateKeyvault ? indexOf(keyVaultResourceId, '/resourceGroups/') : 0)
var keyvaultSubscriptionId = substring(keyVaultResourceId, kvSubIndexStart, (kvSubIndexEnd - kvSubIndexStart))

module nestedTemplate './keyvaultAccessPolicy.bicep' = if (updateKeyvault == bool('true')) {
  name: 'nestedTemplate'
  scope: resourceGroup(keyvaultSubscriptionId, keyvaultResourceGroup)
  params: {
    userAssignedIdentity: reference(userAssignedIdentity.id, '2018-11-30')
    keyVaultName: keyvaultName
    keysPermissions: keysPermissions
    secretsPermissions: secretsPermissions
    certificatePermissions: certificatePermissions
  }
}

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: userAssignedIdentityName
  location: location
}

resource vmIdentityRoleNameGuid_resource 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  scope: userAssignedIdentity
  name: vmIdentityRoleNameGuid
  properties: {
    roleDefinitionId: reference('/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/${managedIdentityProviderGuid}', '2022-04-01').id
    principalId: sfrpProviderGuid
  }
}

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
    vmManagedIdentity: {
      userAssignedIdentities: [
        userAssignedIdentity.id
      ]
    }
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
            authenticationSettings: {
              msiEndpoint: 'http://169.254.169.254/metadata/identity/oauth2/token'
              msiClientId: reference(userAssignedIdentity.id, '2018-11-30').clientId
            }
          }
        }
      }
    ]
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
    vmManagedIdentity: {
      userAssignedIdentities: [
        userAssignedIdentity.id
      ]
    }
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
output keyvaultName string = keyvaultName
output keyvaultResourceGroup string = keyvaultResourceGroup
output keyvaultSubscriptionId string = keyvaultSubscriptionId
output updateKeyvault bool = (updateKeyvault == bool('true'))
output kvresourceId string = (updateKeyvault ? resourceId(keyvaultSubscriptionId, keyvaultResourceGroup, 'Microsoft.KeyVault/vaults', keyvaultName) : '')
