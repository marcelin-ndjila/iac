@description('The location where resources are deployed.')
param location string = resourceGroup().location

@description('The name of the size of the virtual machine to deploy.')
param virtualMachineSizeName string = 'Standard_D2s_v3'

@description('The name of the storage account SKU to use for the virtual machine\'s managed disk.')
param virtualMachineManagedDiskStorageAccountType string = 'Premium_LRS'

@description('The administrator username for the virtual machine.')
param virtualMachineAdminUsername string = 'toytruckadmin'

@description('The administrator password for the virtual machine.')
@secure()
param virtualMachineAdminPassword string

@description('The name of the SKU of the public IP address to deploy.')
param publicIPAddressSkuName string = 'Standard'

@description('The virtual network address range.')
param virtualNetworkAddressPrefix string

@description('The default subnet address range within the virtual network')
param virtualNetworkDefaultSubnetAddressPrefix string

var virtualMachineName = 'ToyTruckServer'
var networkInterfaceName = 'toytruckserver182'
var publicIPAddressName = 'ToyTruckServer-ip'
var virtualNetworkName = 'ToyTruckServer-vnet'
var networkSecurityGroupName = 'ToyTruckServer-nsg'
var virtualNetworkDefaultSubnetName = 'default'
var virtualMachineImageReference = {
  publisher: 'canonical'
  offer: '0001-com-ubuntu-server-focal'
  sku: '20_04-lts-gen2'
  version: 'latest'
}
var virtualMachineOSDiskName = '${virtualMachineName}_OsDisk_1_7ec72204b2f948518c4cc8c6e9e9b2bc_b'

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2023-06-01' = {
  name: networkSecurityGroupName
  location: location
 }

resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2023-06-01' = {
  name: publicIPAddressName
  location: location
  sku: {
    name: publicIPAddressSkuName
    tier: 'Regional'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-06-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetworkAddressPrefix
      ]
    }
    subnets: [
      {
        name: virtualNetworkDefaultSubnetName
          properties: {
          addressPrefix: virtualNetworkDefaultSubnetAddressPrefix
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
        type: 'Microsoft.Network/virtualNetworks/subnets'
      }
    ]
    enableDdosProtection: false
  }
  resource defaultSubnet 'subnets' existing = {
    name: virtualNetworkDefaultSubnetName
  }
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: virtualMachineName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: virtualMachineSizeName
    }
    storageProfile: {
      imageReference: virtualMachineImageReference
      osDisk: {
        osType: 'Linux'
        name: virtualMachineOSDiskName
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: virtualMachineManagedDiskStorageAccountType
        }
        deleteOption: 'Delete'
        diskSizeGB: 30
      }
    }
    osProfile: {
      computerName: virtualMachineName
      adminUsername: virtualMachineAdminUsername
      adminPassword: virtualMachineAdminPassword
      linuxConfiguration: {
        disablePasswordAuthentication: false
        provisionVMAgent: true
        patchSettings: {
          patchMode: 'ImageDefault'
          assessmentMode: 'ImageDefault'
        }
        enableVMAgentPlatformUpdates: false
      }
      allowExtensionOperations: true
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
          properties: {
            deleteOption: 'Detach'
          }
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}

resource networkInterface 'Microsoft.Network/networkInterfaces@2023-06-01' = {
  name: networkInterfaceName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddress.id
            properties: {
              deleteOption: 'Detach'
            }
            sku: {
              name: 'Basic'
              tier: 'Regional'
            }
          }
          subnet: {
            id: virtualNetwork::defaultSubnet.id
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    enableAcceleratedNetworking: true
    enableIPForwarding: false
    disableTcpStateTracking: false
    networkSecurityGroup: {
      id: networkSecurityGroup.id
    }
    nicType: 'Standard'
  }
}
