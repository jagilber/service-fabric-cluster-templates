# 5 Node 1 node type secure Windows Service Fabric Cluster with standard load balancer, NSG, and Automatic OS Upgrade

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure-Samples%2Fservice-fabric-cluster-templates%2Fmaster%2F5-VM-Windows-1-NodeType-SLB-Auto%2FAzureDeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2FAzure-Samples%2Fservice-fabric-cluster-templates%2Fmaster%2F5-VM-Windows-1-NodeType-SLB-Auto%2FAzureDeploy.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>

This template allows you to deploy a secure 5 node, 1 Node Type Service Fabric Cluster with Standard load balancer running Windows Server 2022 Datacenter on a Standard_DS4_v2 Size Virtual Machine Scale set.

## Template Configuration

- Cluster Reliability Level: Silver or higher
- Certificate Thumbprint configuration
- Automatic OS Upgrade configuration

## Template Resources

- 1 service fabric cluster
- 1 vm scale set / node type
  - 5 nodes / virtual machines
  - 2 extensions
    - Service Fabric
    - Iaas Diagnostic
- 1 standard load balancer
- 1 public IP address
- 1 network security group
- 1 virtual network
- 2 storage account v2
  - diagnostics
  - service fabric logs

## Certificate needed for the template if using the 'Deploy to Azure' button above

This template assumes that you already have certificates uploaded to your key vault. Production clusters should always use a CA signed certificate. If needing a certificate for testing, a .pfx certificate can be generated directly in the key vault or if you want to create a new certificate run the [New-ServiceFabricClusterCertificate.ps1](../scripts/New-ServiceFabricClusterCertificate.ps1) file in this repository. That script will output the values necessary for deployment via the parameters file.

**NOTE: Azure Key vault 'Access Configuration' should have 'Azure Virtual Machines for deployment' and 'Azure Resource Manager for template deployment' enabled for node key vault access during template deployment.**

You can download the .PFX from the key vault from the portal

- Go to the key vault resource
- navigate to the secrets tab and download the .pfx

![DownloadCert]

## Use Powershell to deploy your cluster

Go through the process of creating the cluster as described in [Creating Service Fabric Cluster via arm](https://docs.microsoft.com/azure/service-fabric/service-fabric-cluster-creation-via-arm)

## Creating a custom ARM template

If you are wanting to create a custom ARM template for your cluster, then you have two choices.

1. You can acquire this sample template and make changes to it.
2. Log into the azure portal and use the service fabric portal pages to generate the template for you to customize.

    - Log on to the Azure Portal [http://aka.ms/servicefabricportal](http://aka.ms/servicefabricportal).
    - Go through the process of creating the cluster as described in [Creating Service Fabric Cluster via portal](https://docs.microsoft.com/azure/service-fabric/service-fabric-cluster-creation-via-portal) , but do not click on ***create**, instead go to Summary and download the template and parameters.

 ![DownloadTemplate][DownloadTemplate]

Unzip the downloaded .zip on your local machine, make any changes to template or the parameter file as you need.

<!--Image references-->
[DownloadTemplate]: ../media/DownloadTemplate.png
[DownloadCert]: ../media/DownloadCert.PNG