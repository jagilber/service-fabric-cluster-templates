# Additional Nodetype for Windows Service Fabric Cluster with standard load balancer, NSG, and Automatic OS Upgrade

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure-Samples%2Fservice-fabric-cluster-templates%2Fmaster%2FSF-Windows-Additional-NodeType-SLB%2FAzureDeploy.json)
[![Visualize](http://armviz.io/visualizebutton.png)](http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2FAzure-Samples%2Fservice-fabric-cluster-templates%2Fmaster%2FSF-Windows-Additional-NodeType-SLB%2FAzureDeploy.json)

This template allows you to deploy an additional node type to an existing Service Fabric Cluster running Windows Server 2022 Datacenter on a Standard_DS4_v2 Size Virtual Machine Scale set. Bronze clusters are considered development clusters and should not be used in production. Template requires an existing Service Fabric cluster and an existing `nodeTypes` configuration. See [NodeTypeDescription](https://learn.microsoft.com/azure/templates/microsoft.servicefabric/clusters?pivots=deployment-language-arm-template#nodetypedescription-1)

## Template Configuration

- Cluster Durability Level: Bronze or higher
- Certificate Thumbprint configuration
- Automatic OS Upgrade configuration

## Template Prerequisites

- Existing Service Fabric Cluster
- Existing Service Fabric Cluster nodetype configuration

## Template Resources

- 1 vm scale set / node type
  - x nodes / virtual machines
  - 2 extensions
    - Service Fabric
    - Iaas Diagnostic
- 1 standard load balancer
- 1 public IP address
- 1 network security group
- 2 storage account v2
  - diagnostics
  - service fabric logs

### Example nodetype configuration prerequisite for Microsoft.ServiceFabric/clusters resource:

- NodeType0 is the primary node type currently provisioned in cluster.
- NodeType1 is the additional node type being added with this template which must be included in the nodeTypes array before deployment of this template.

```json
"nodeTypes": [
  {
    "name": "nodetype0",
    "clientConnectionEndpointPort": 19000,
    "httpGatewayEndpointPort": 19080,
    "applicationPorts": {
        "startPort": 20000,
        "endPort": 30000
    },
    "ephemeralPorts": {
        "startPort": 49152,
        "endPort": 65534
    },
    "isPrimary": true,
    "durabilityLevel": "Silver",
    "vmInstanceCount": 5,
    "isStateless": false
  },
  {
    "name": "nodetype1",
    "clientConnectionEndpointPort": 19001,
    "httpGatewayEndpointPort": 19081,
    "applicationPorts": {
        "startPort": 30001,
        "endPort": 40000
    },
    "ephemeralPorts": {
        "startPort": 49152,
        "endPort": 65534
    },
    "isPrimary": false,
    "durabilityLevel": "Silver",
    "vmInstanceCount": 5,
    "isStateless": true
  }
]
```

### Example Parameter File

Example cluster configuration:

- Existing Cluster Name: testservicefabriccluster
- Existing Cluster Resource Group Name: testservicefabricclusterrg
- Existing DNS Name: testservicefabriccluster.eastus.cloudapp.azure.com
- Existing Support Log Storage Account Name: testsfdiagnostics
- Existing Support Log Storage Account Resource Group Name: testservicefabricclusterrg
- Existing Application Logs Storage Account Name: testsfapplogs
- Existing Application Logs Storage Account Resource Group Name: testservicefabricclusterrg
- Virtual Network Name: testvnet
- Subnet Name: testsubnet
- NodeType0 is the primary node type currently provisioned in cluster.
- NodeType1 is the additional node type being added with this template which must be included in the nodeTypes array before deployment of this template.

```json
{
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "adminPassword": {
            "value": "GEN-PASSWORD"
        },
        "adminUsername": {
            "value": "GEN-UNIQUE"
        },
        "certificateThumbprint": {
            "value": "GEN-CUSTOM-DOMAIN-SSLCERT-THUMBPRINT"
        },
        "certificateUrlValue": {
            "value": "GEN-KEYVAULT-SSL-SECRET-URI"
        },
        "dnsName": {
            "value": "testservicefabriccluster1"
        },
        "durabilityLevel": {
            "value": "Silver"
        },
        "enableAutomaticOSUpgrade": {
            "value": true
        },
        "existingApplicationDiagnosticsStorageAccountName": {
            "value": "testsfdiagnostics"
        },
        "existingApplicationDiagnosticsStorageAccountRGName": {
            "value": "testservicefabricclusterrg"
        },
        "existingClusterName": {
            "value": "testservicefabriccluster"
        },
        "existingClusterRGName": {
            "value": "testservicefabricclusterrg"
        },
        "existingNodeTypeRef": {
            "value": "nodetype0"
        },
        "existingSupportLogStorageAccountName": {
            "value": "testsfdiagnostics"
        },
        "existingSupportLogStorageAccountRGName": {
            "value": "testservicefabricclusterrg"
        },
        "keyVaultResourceId": {
          "value": "GEN-KEYVAULT-RESOURCE-ID"
        },
        "lbIPName": {
          "value": "GEN-NEW-LB-PUBLIC-IP-NAME"
        },
        "ntInstanceCount": {
          "value": 5
        },
        "subnetName": {
            "value": "testsubnet"
        },
        "vmImageSku": {
          "value": "2022-Datacenter"
        },
        "vmNodeTypeName": {
          "value": "nodetype1"
        },
        "vmNodeTypeSize": {
          "value": "Standard_DS4_v2"
        },
        "vnetName": {
            "value": "testvnet"
        }
    }
}
```

## Certificates

This template assumes that you already have certificates uploaded to your key vault. Production clusters should always use a CA signed certificate. If needing a certificate for testing, a .pfx certificate can be generated directly in the key vault or if you want to create a new certificate run the [New-ServiceFabricClusterCertificate.ps1](../scripts/New-ServiceFabricClusterCertificate.ps1) file in this repository. That script will output the values necessary for deployment via the parameters file.

> [!NOTE]
> Azure Key vault 'Access Configuration' should have 'Azure Virtual Machines for deployment' and 'Azure Resource Manager for template deployment' enabled for node key vault access during template deployment.

You can download the .PFX from the key vault from the portal

- Go to the key vault resource
- navigate to the secrets tab and download the .pfx

![DownloadCert][DownloadCert]

## Use Powershell to deploy your cluster

Execute from a machine with Azure 'Az.Accounts' and 'Az.Resources' modules installed. Optionally, uncomment the `Install-Module` lines to install the modules if not already installed.

```powershell
# Install-Module -Name Az.Accounts -AllowClobber -Scope CurrentUser
# Install-Module -Name Az.Resources -AllowClobber -Scope CurrentUser
Import-Module Az.Accounts
Import-Module Az.Resources
Connect-AzAccount

$location = '<location>'
$resourceGroupName = '<resource group name>'
$templateFile = '.\azuredeploy.json'
$templateParameterFile = '.\azuredeploy.parameters.json'

New-AzResourceGroup -Name $resourceGroupName -Location $location
New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName `
            -DeploymentDebugLogLevel All `
            -TemplateFile $templateFile `
            -TemplateParameterFile $templateParameterFile `
            -Verbose
```

## Use Powershell to connect to your cluster

Execute from a windows powershell command prompt with the Service Fabric SDK installed. The Service Fabric SDK can be installed from the [Download and install the runtime and SDK](https://learn.microsoft.com/azure/service-fabric/service-fabric-get-started) page.

```powershell
Import-Module ServiceFabric

$location = '<location>'
$clusterName = '<cluster name>'
$serverCertThumbprint = '<cluster certificate thumbprint>'

$clusterFqdn = "$clusterName.$location.cloudapp.azure.com"
$clusterEndpoint = "$($clusterFqdn):19000"
# if using client thumbprint
Connect-ServiceFabricCluster -ConnectionEndpoint $clusterEndpoint `
    -ServerCertThumbprint $serverCertThumbprint `
    -StoreLocation CurrentUser `
    -StoreName My `
    -X509Credential `
    -FindType FindByThumbprint `
    -FindValue '<client certificate thumbprint>' `
    -Verbose
# or if using client common name
Connect-ServiceFabricCluster -ConnectionEndpoint $clusterEndpoint `
    -ServerCertThumbprint $serverCertThumbprint `
    -StoreLocation CurrentUser `
    -StoreName My `
    -X509Credential `
    -FindType FindBySubjectName `
    -FindValue '<client certificate subject name>' `
    -Verbose
```

<!--Image references-->

[DownloadCert]: ../media/DownloadCert.PNG
