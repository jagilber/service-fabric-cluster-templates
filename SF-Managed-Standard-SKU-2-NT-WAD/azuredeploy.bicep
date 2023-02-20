@description('Resource Group')
param location string = resourceGroup().location

@secure()
param adminPassword string
param adminUserName string
param clientCertificateThumbprint string
param clusterName string
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

@description('generate guid one time and reuse for same assignment: [guid]::NewGuid() ')
param roleAssignmentId string

@description('https://docs.microsoft.com/azure/role-based-access-control/role-definitions-list \'Managed Identity Operator\' read and assign')
param roleDefinitionId string = 'f1a07417-d97a-45cb-824c-7a7467783830'
param storageAccountName string = 'sfmcevts${uniqueString(resourceGroup().id)}'

@description('to enumerate tenant specific SFRP guid: Select-AzSubscription -SubscriptionId {{subscription id}}; Get-AzADServicePrincipal -DisplayName \'Azure Service Fabric Resource Provider\'')
param subscriptionSFRPId string
param userAssignedIdentity string = 'sfmcevts'

var dataDiskLetter = 'S'

resource roleAssignmentID_resource 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  scope: userAssignedIdentity_resource
  name: roleAssignmentId
  properties: {
    roleDefinitionId: reference('/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/${roleDefinitionId}', '2022-04-01').id
    principalId: subscriptionSFRPId
  }
}

resource userAssignedIdentity_resource 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: userAssignedIdentity
  location: location
}

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

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: storageAccountName
  location: location
  properties: {
  }
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  tags: {
    resourceType: 'Service Fabric'
    clusterName: clusterName
  }
  dependsOn: []
}

resource clusterName_nodeType1 'Microsoft.ServiceFabric/managedClusters/nodetypes@2022-01-01' = {
  parent: cluster
  name: nodeType1Name
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
    vmManagedIdentity: {
      userAssignedIdentities: [
        userAssignedIdentity_resource.id
      ]
    }
    dataDiskLetter: dataDiskLetter
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
        name: 'VMDiagnosticsVmExt-${nodeType1Name}'
        properties: {
          type: 'IaaSDiagnostics'
          autoUpgradeMinorVersion: true
          protectedSettings: {
            storageAccountName: storageAccountName
            storageAccountKey: listKeys(storageAccount.id, '2015-05-01-preview').key1
            #disable-next-line no-hardcoded-env-urls
            storageAccountEndPoint: 'https://core.windows.net/'
          }
          publisher: 'Microsoft.Azure.Diagnostics'
          settings: {
            WadCfg: {
              DiagnosticMonitorConfiguration: {
                overallQuotaInMB: '50000'
                PerformanceCounters: {
                  scheduledTransferPeriod: 'PT1M'
                  sinks: 'AzMonSink'
                  PerformanceCounterConfiguration: [
                    {
                      counterSpecifier: '\\LogicalDisk(C:)\\% Free Space'
                      sampleRate: 'PT10S'
                    }
                    {
                      counterSpecifier: '\\LogicalDisk(${dataDiskLetter}:)\\% Free Space'
                      sampleRate: 'PT10S'
                    }
                    {
                      counterSpecifier: '\\Memory\\Available MBytes'
                      sampleRate: 'PT10S'
                    }
                    {
                      counterSpecifier: '\\Memory\\Pages/sec'
                      sampleRate: 'PT10S'
                    }
                    {
                      counterSpecifier: '\\Paging File(_Total)\\% Usage'
                      sampleRate: 'PT10S'
                    }
                    {
                      counterSpecifier: '\\PhysicalDisk(C:)\\Current Disk Queue Length'
                      sampleRate: 'PT10S'
                    }
                    {
                      counterSpecifier: '\\PhysicalDisk(${dataDiskLetter}:)\\Current Disk Queue Length'
                      sampleRate: 'PT10S'
                    }
                    {
                      counterSpecifier: '\\Process(_Total)\\Handle Count'
                      sampleRate: 'PT10S'
                    }
                    {
                      counterSpecifier: '\\Process(_Total)\\Private Bytes'
                      sampleRate: 'PT10S'
                    }
                    {
                      counterSpecifier: '\\Process(_Total)\\Thread Count'
                      sampleRate: 'PT10S'
                    }
                    {
                      counterSpecifier: '\\Processor(_Total)\\% Processor Time'
                      sampleRate: 'PT10S'
                    }
                    {
                      counterSpecifier: '\\TCPv4\\Connections Established'
                      sampleRate: 'PT10S'
                    }
                    {
                      counterSpecifier: '\\TCPv4\\Segments Received/sec'
                      sampleRate: 'PT10S'
                    }
                    {
                      counterSpecifier: '\\TCPv4\\Segments Retransmitted/sec'
                      sampleRate: 'PT10S'
                    }
                    {
                      counterSpecifier: '\\TCPv4\\Segments Sent/sec'
                      sampleRate: 'PT10S'
                    }
                  ]
                }
                EtwProviders: {
                  EtwEventSourceProviderConfiguration: [
                    {
                      provider: 'Microsoft-ServiceFabric-Actors'
                      scheduledTransferKeywordFilter: '1'
                      scheduledTransferPeriod: 'PT5M'
                      DefaultEvents: {
                        eventDestination: 'ServiceFabricReliableActorEventTable'
                      }
                    }
                    {
                      provider: 'Microsoft-ServiceFabric-Services'
                      scheduledTransferPeriod: 'PT5M'
                      DefaultEvents: {
                        eventDestination: 'ServiceFabricReliableServiceEventTable'
                      }
                    }
                  ]
                  EtwManifestProviderConfiguration: [
                    {
                      provider: 'cbd93bc2-71e5-4566-b3a7-595d8eeca6e8'
                      scheduledTransferLogLevelFilter: 'Information'
                      scheduledTransferKeywordFilter: '4611686018427387904'
                      scheduledTransferPeriod: 'PT5M'
                      DefaultEvents: {
                        eventDestination: 'ServiceFabricSystemEventTable'
                      }
                    }
                    {
                      provider: '02d06793-efeb-48c8-8f7f-09713309a810'
                      scheduledTransferLogLevelFilter: 'Information'
                      scheduledTransferKeywordFilter: '4611686018427387904'
                      scheduledTransferPeriod: 'PT5M'
                      DefaultEvents: {
                        eventDestination: 'ServiceFabricSystemEventTable'
                      }
                    }
                  ]
                }
                WindowsEventLog: {
                  scheduledTransferPeriod: 'PT5M'
                  DataSource: [
                    {
                      name: 'System!*[System[Provider[@Name=\'Microsoft Antimalware\']]]'
                    }
                    {
                      name: 'System!*[System[Provider[@Name=\'NTFS\'] and (EventID=55)]]'
                    }
                    {
                      name: 'System!*[System[Provider[@Name=\'disk\'] and (EventID=7 or EventID=52 or EventID=55)]]'
                    }
                    {
                      name: 'Application!*[System[(Level=1 or Level=2 or Level=3)]]'
                    }
                    {
                      name: 'Microsoft-ServiceFabric/Admin!*[System[(Level=1 or Level=2 or Level=3)]]'
                    }
                    {
                      name: 'Microsoft-ServiceFabric/Audit!*[System[(Level=1 or Level=2 or Level=3)]]'
                    }
                    {
                      name: 'Microsoft-ServiceFabric/Operational!*[System[(Level=1 or Level=2 or Level=3)]]'
                    }
                  ]
                }
              }
              SinksConfig: {
                Sink: [
                  {
                    name: 'AzMonSink'
                    AzureMonitor: {
                      resourceId: ''
                    }
                  }
                  {
                    name: 'ApplicationInsights'
                    ApplicationInsights: '***ADD INSTRUMENTATION KEY HERE***'
                  }
                  {
                    name: 'EventHub'
                    EventHub: {
                      Url: 'https://myeventhub-ns.servicebus.windows.net/diageventhub'
                      SharedAccessKeyName: 'SendRule'
                      usePublisherId: false
                    }
                  }
                ]
              }
            }
          }
          typeHandlerVersion: '1.5'
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
    vmImageSku: '2019-Datacenter'
    vmImageVersion: 'latest'
    vmSize: nodeType2VmSize
    vmInstanceCount: nodeType2VmInstanceCount
    dataDiskSizeGB: nodeType2DataDiskSizeGB
    dataDiskType: nodeType2managedDataDiskType
    vmManagedIdentity: {
      userAssignedIdentities: [
        userAssignedIdentity_resource.id
      ]
    }
    dataDiskLetter: dataDiskLetter
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
        name: 'VMDiagnosticsVmExt${nodeType2Name}'
        properties: {
          type: 'IaaSDiagnostics'
          autoUpgradeMinorVersion: true
          protectedSettings: {
            storageAccountName: storageAccountName
            storageAccountKey: listKeys(storageAccount.id, '2015-05-01-preview').key1
            #disable-next-line no-hardcoded-env-urls
            storageAccountEndPoint: 'https://core.windows.net/'
          }
          publisher: 'Microsoft.Azure.Diagnostics'
          settings: {
            WadCfg: {
              DiagnosticMonitorConfiguration: {
                overallQuotaInMB: '50000'
                PerformanceCounters: {
                  scheduledTransferPeriod: 'PT1M'
                  sinks: 'AzMonSink'
                  PerformanceCounterConfiguration: [
                    {
                      counterSpecifier: '\\LogicalDisk(C:)\\% Free Space'
                      sampleRate: 'PT10S'
                    }
                    {
                      counterSpecifier: '\\LogicalDisk(${dataDiskLetter}:)\\% Free Space'
                      sampleRate: 'PT10S'
                    }
                    {
                      counterSpecifier: '\\Memory\\Available MBytes'
                      sampleRate: 'PT10S'
                    }
                    {
                      counterSpecifier: '\\Memory\\Pages/sec'
                      sampleRate: 'PT10S'
                    }
                    {
                      counterSpecifier: '\\Paging File(_Total)\\% Usage'
                      sampleRate: 'PT10S'
                    }
                    {
                      counterSpecifier: '\\PhysicalDisk(C:)\\Current Disk Queue Length'
                      sampleRate: 'PT10S'
                    }
                    {
                      counterSpecifier: '\\PhysicalDisk(${dataDiskLetter}:)\\Current Disk Queue Length'
                      sampleRate: 'PT10S'
                    }
                    {
                      counterSpecifier: '\\Process(_Total)\\Handle Count'
                      sampleRate: 'PT10S'
                    }
                    {
                      counterSpecifier: '\\Process(_Total)\\Private Bytes'
                      sampleRate: 'PT10S'
                    }
                    {
                      counterSpecifier: '\\Process(_Total)\\Thread Count'
                      sampleRate: 'PT10S'
                    }
                    {
                      counterSpecifier: '\\Processor(_Total)\\% Processor Time'
                      sampleRate: 'PT10S'
                    }
                    {
                      counterSpecifier: '\\TCPv4\\Connections Established'
                      sampleRate: 'PT10S'
                    }
                    {
                      counterSpecifier: '\\TCPv4\\Segments Received/sec'
                      sampleRate: 'PT10S'
                    }
                    {
                      counterSpecifier: '\\TCPv4\\Segments Retransmitted/sec'
                      sampleRate: 'PT10S'
                    }
                    {
                      counterSpecifier: '\\TCPv4\\Segments Sent/sec'
                      sampleRate: 'PT10S'
                    }
                  ]
                }
                EtwProviders: {
                  EtwEventSourceProviderConfiguration: [
                    {
                      provider: 'Microsoft-ServiceFabric-Actors'
                      scheduledTransferKeywordFilter: '1'
                      scheduledTransferPeriod: 'PT5M'
                      DefaultEvents: {
                        eventDestination: 'ServiceFabricReliableActorEventTable'
                      }
                    }
                    {
                      provider: 'Microsoft-ServiceFabric-Services'
                      scheduledTransferPeriod: 'PT5M'
                      DefaultEvents: {
                        eventDestination: 'ServiceFabricReliableServiceEventTable'
                      }
                    }
                  ]
                  EtwManifestProviderConfiguration: [
                    {
                      provider: 'cbd93bc2-71e5-4566-b3a7-595d8eeca6e8'
                      scheduledTransferLogLevelFilter: 'Information'
                      scheduledTransferKeywordFilter: '4611686018427387904'
                      scheduledTransferPeriod: 'PT5M'
                      DefaultEvents: {
                        eventDestination: 'ServiceFabricSystemEventTable'
                      }
                    }
                    {
                      provider: '02d06793-efeb-48c8-8f7f-09713309a810'
                      scheduledTransferLogLevelFilter: 'Information'
                      scheduledTransferKeywordFilter: '4611686018427387904'
                      scheduledTransferPeriod: 'PT5M'
                      DefaultEvents: {
                        eventDestination: 'ServiceFabricSystemEventTable'
                      }
                    }
                  ]
                }
                WindowsEventLog: {
                  scheduledTransferPeriod: 'PT5M'
                  DataSource: [
                    {
                      name: 'System!*[System[Provider[@Name=\'Microsoft Antimalware\']]]'
                    }
                    {
                      name: 'System!*[System[Provider[@Name=\'NTFS\'] and (EventID=55)]]'
                    }
                    {
                      name: 'System!*[System[Provider[@Name=\'disk\'] and (EventID=7 or EventID=52 or EventID=55)]]'
                    }
                    {
                      name: 'Application!*[System[(Level=1 or Level=2 or Level=3)]]'
                    }
                    {
                      name: 'Microsoft-ServiceFabric/Admin!*[System[(Level=1 or Level=2 or Level=3)]]'
                    }
                    {
                      name: 'Microsoft-ServiceFabric/Audit!*[System[(Level=1 or Level=2 or Level=3)]]'
                    }
                    {
                      name: 'Microsoft-ServiceFabric/Operational!*[System[(Level=1 or Level=2 or Level=3)]]'
                    }
                  ]
                }
              }
              SinksConfig: {
                Sink: [
                  {
                    name: 'AzMonSink'
                    AzureMonitor: {
                      resourceId: ''
                    }
                  }
                  {
                    name: 'ApplicationInsights'
                    ApplicationInsights: '***ADD INSTRUMENTATION KEY HERE***'
                  }
                  {
                    name: 'EventHub'
                    EventHub: {
                      Url: 'https://myeventhub-ns.servicebus.windows.net/diageventhub'
                      SharedAccessKeyName: 'SendRule'
                      usePublisherId: false
                    }
                  }
                ]
              }
            }
          }
          typeHandlerVersion: '1.5'
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
