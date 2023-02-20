@description('Region')
param location string = resourceGroup().location

param clusterName string

@maxLength(9)
param nodeType2Name string = 'NT2'
param enableAutoScale bool = true

resource clusterName_nodeType2 'Microsoft.Insights/autoscaleSettings@2015-04-01' = {
  name: '${clusterName}-${nodeType2Name}'
  location: location
  properties: {
    name: '${clusterName}-${nodeType2Name}'
    targetResourceUri: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.ServiceFabric/managedclusters/${clusterName}/nodetypes/${nodeType2Name}'
    enabled: enableAutoScale
    profiles: [
      {
        name: 'Autoscale by percentage based on CPU usage'
        capacity: {
          minimum: '3'
          maximum: '20'
          default: '3'
        }
        rules: [
          {
            metricTrigger: {
              metricName: 'Percentage CPU'
              metricNamespace: ''
              metricResourceUri: '/subscriptions/${subscription().subscriptionId}/resourceGroups/SFC_${reference(resourceId('Microsoft.ServiceFabric/managedClusters', clusterName), '2021-07-01-preview').clusterId}/providers/Microsoft.Compute/virtualMachineScaleSets/${nodeType2Name}'
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT30M'
              timeAggregation: 'Average'
              operator: 'GreaterThan'
              threshold: 70
            }
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: '5'
              cooldown: 'PT5M'
            }
          }
          {
            metricTrigger: {
              metricName: 'Percentage CPU'
              metricNamespace: ''
              metricResourceUri: '/subscriptions/${subscription().subscriptionId}/resourceGroups/SFC_${reference(resourceId('Microsoft.ServiceFabric/managedClusters', clusterName), '2021-07-01-preview').clusterId}/providers/Microsoft.Compute/virtualMachineScaleSets/${nodeType2Name}'
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT30M'
              timeAggregation: 'Average'
              operator: 'LessThan'
              threshold: 40
            }
            scaleAction: {
              direction: 'Decrease'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
          }
        ]
      }
    ]
  }
}
