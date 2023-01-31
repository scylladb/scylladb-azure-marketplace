@description('Deployment Location')
param location string = resourceGroup().location

@description('Name of VMSS Cluster')
param vmssName string

@description('GameDev Sku')
param vmssSku string = 'Standard_D4ds_v4'

@description('Image Publisher')
@allowed([
  'scylladb1631195365807'
])
param vmssImgPublisher string = 'scylladb1631195365807'

@description('Image Product Id')
@allowed([
  'scylla-enterprise'
])
param vmssImgProduct string = 'scylla-enterprise'

@description('Image Sku')
@allowed([
  'scylla-enterprise-vm'
])
param vmssImgSku string = 'scylla-enterprise-vm'

@description('GameDev Image Product Id')
param vmssImgVersion string = 'latest'

@description('GameDev Disk Type')
param vmssOsDiskType string = 'Premium_LRS'

@description('VMSS Instance Count')
@maxValue(100)
@minValue(1)
param vmssInstanceCount int = 1

@description('Administrator Login for access')
param administratorLogin string

@description('Administrator Password for access')
@secure()
param passwordAdministratorLogin string

@description('Virtual Network Resource Name')
param vnetName string = 'vnet-${vmssName}'

@description('Virtual Network Subnet Name')
param subnetName string = 'subnet${vmssName}'

@description('Virtual Network Security Group Name')
param networkSecurityGroupName string = 'nsg-${vmssName}'

@description('Virtual Network Address Prefix')
param vnetAddressPrefix array = [ '172.17.72.0/24' ] //Change as needed

@description('Virtual Network Subnet Address Prefix')
param subnetAddressPrefix string = '172.17.72.0/25' // 172.17.72.[0-128] is part of this subnet

@allowed([
  'gallery'
  'marketplace'
])
@description('Parameter used for debugging with trail offer')
param imageLocation string = 'marketplace'

var sharedGallery = 'ScyllaDB-f6e972a4-92ec-4c3c-8999-11b863cad0f7'
var definition = 'ScyllaDB_Enterprise'
var imageVer = 'latest'

var locations = {
  gallery: {
    plan: null
    imageReference: { communityGalleryImageId: '/CommunityGalleries/${sharedGallery}/Images/${definition}/Versions/${imageVer}' }
  }
  marketplace: {
    plan: {
      name:      vmssImgSku
      publisher: vmssImgPublisher
      product:   vmssImgProduct
    }
    imageReference: {
      publisher: vmssImgPublisher
      offer:     vmssImgProduct
      sku:       vmssImgSku
      version:   vmssImgVersion
    }
  }
}

resource partnercenter 'Microsoft.Resources/deployments@2021-04-01' = {
  name: 'pid-7837dd60-4ba8-419a-a26f-237bbe170773-partnercenter'
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      resources: []
    }
  }
}

module vnet './nestedtemplates/virtualNetworks.bicep'  = {
  name:                       vnetName
  params: {
    location:                 location
    vnetName:                 vnetName
    subnetName:               subnetName
    networkSecurityGroupName: networkSecurityGroupName
    vnetAddressPrefix:        vnetAddressPrefix
    subnetAddressPrefix:      subnetAddressPrefix
  }
}

resource vmss 'Microsoft.Compute/virtualMachineScaleSets@2022-03-01' = {
  name: vmssName
  location: location
  sku: {
    name:     vmssSku
    tier:     'Standard'
    capacity: vmssInstanceCount
  }
  plan: locations[imageLocation].plan
  properties: {
    singlePlacementGroup: false
    upgradePolicy: {
      mode: 'Manual'
    }
    virtualMachineProfile: {
      storageProfile: {
        osDisk: {
          createOption: 'FromImage'
          caching: 'ReadWrite'
          managedDisk: {
            storageAccountType: vmssOsDiskType
          }
        }
        imageReference: locations[imageLocation].imageReference
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: '${vmssName}Nic'
            properties: {
              primary: true
              ipConfigurations: [
                {
                  name: '${vmssName}IpConfig'
                  properties: {
                    subnet: {
                      id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
                    }
                  }
                }
              ]
              networkSecurityGroup: {
                id: vnet.outputs.nsgID
              }
            }
          }
        ]
      }
      osProfile: {
        computerNamePrefix: vmssName
        adminUsername:      administratorLogin
        adminPassword:      passwordAdministratorLogin
        customData: loadFileAsBase64('scyllaDBConfig.json')
      }
      priority: 'Regular'
    }
    overprovision: false
  }
}

output id   string = vmss.id
output name string = vmss.name
