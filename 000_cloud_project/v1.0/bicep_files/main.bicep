/* -------------------------------------------------------------------------- */
/*                     Use this command to deploy                             */
/* -------------------------------------------------------------------------- */

// az login
// az account set --subscription 'Cloud Student 1'
// az group create --name TestRGcloud_project --location westeurope
// az deployment group create --resource-group TestRGcloud_project --template-file main.bicep

/* -------------------------------------------------------------------------- */
/*                     LOCATION FOR EVERY RESOURCE                            */
/* -------------------------------------------------------------------------- */

// location
@description('Location for all resources.')
param location string = resourceGroup().location

/* -------------------------------------------------------------------------- */
/* -------------------------------------------------------------------------- */
/* -------------------------------------------------------------------------- */
/* -------------------------------------------------------------------------- */
/* -------------------------------------------------------------------------- */
/* -------------------------------------------------------------------------- */
/* -------------------------------------------------------------------------- */
/*                              Management                                    */
/* -------------------------------------------------------------------------- */

// ToDo:
//  - Adjust this according to requirements

// Management Server: 10.20.20.0/24
// Web/App Server: 10.10.10.0/24

/* -------------------------------------------------------------------------- */
/*                     PARAMS & VARS                                          */
/* -------------------------------------------------------------------------- */

// vnet
var virtualNetworkName = 'management-vnet'
// subnet
var subnetName = 'management-subnet'
// nsg
var nsgName = 'management-nsg'
// public ip
var publicIpName = 'management-public-ip'
// nic
var nicName = 'management-nic'
// addressPrefixes
var vnet_addressPrefixes = '10.20.20.0/24'
// // DNS
// var DNSdomainNameLabel = 'management-server'
// IP config
var IPConfigName = 'management-ipconfig'

/* -------------------------------------------------------------------------- */
/*                     Virtual Network with subnet                            */
/* -------------------------------------------------------------------------- */

resource vnetManagement 'Microsoft.Network/virtualNetworks@2022-11-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnet_addressPrefixes
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: vnet_addressPrefixes
          // By associating an NSG with a subnet, we can enforce network-level security policies for the resources within that subnet.
          networkSecurityGroup: {
            id: resourceId('Microsoft.Network/networkSecurityGroups', nsgName)
          }
        }
      }
    ]
  }
}

/* -------------------------------------------------------------------------- */
/*                     Network Security Group                                 */
/* -------------------------------------------------------------------------- */
// managementNSG: The management NSG is created next. It depends on the managementSubnet 
// because the security rules in the NSG refer to the address prefixes of the management subnet. 
// By placing the NSG definition next, we ensure that the subnet is available and its properties
// are accessible when defining the security rules.

param allowedIPAddresses array = [ '85.149.106.77' ]

resource nsgManagement 'Microsoft.Network/networkSecurityGroups@2022-11-01' = {
  name: nsgName
  location: location
  // Contains the set of properties for the NSG, including the security rules.
  properties: {
    // security rules are An array of security rules that define the network traffic rules for the NSG.
    securityRules: [
      // {
      //   name: 'All-IP-Blocked'
      //   properties: {
      //     description: 'Block all IP addresses except the specific IP'
      //     // priority: Lower values indicate higher priority. In this case, the rule has a priority of 100.
      //     priority: 200
      //     access: 'Deny'
      //     // direction: Indicates the direction of the traffic. 'Inbound' means the rule applies to incoming traffic.
      //     direction: '*'
      //     protocol: '*'
      //     sourcePortRange: '*'
      //     destinationPortRange: '*'
      //     // sourceAddressPrefixes: Defines the source IP addresses or ranges allowed for the traffic. You can add trusted source IP addresses or ranges that are allowed to access the management server.
      //     sourceAddressPrefixes: [ '0.0.0.0/0' ]
      //     // destinationAddressPrefixes: Specifies the destination IP addresses or ranges for the traffic. In this case, it is set to '10.20.20.0/24', which represents the IP address range of the management subnet.
      //     destinationAddressPrefixes: []
      //   }
      // }
      // // Add additional security rules as needed
      // {
      //   name: 'Allow-Admin-Inbound'
      //   properties: {
      //     description: 'Allow inbound connections from trusted locations'
      //     // priority: Lower values indicate higher priority. In this case, the rule has a priority of 100.
      //     priority: 100
      //     access: 'Allow'
      //     // direction: Indicates the direction of the traffic. 'Inbound' means the rule applies to incoming traffic.
      //     direction: 'Inbound'
      //     // 'Tcp'?
      //     protocol: '*'
      //     sourcePortRange: '*'
      //     destinationPortRange: '*'
      //     // sourceAddressPrefixes: Defines the source IP addresses or ranges allowed for the traffic. You can add trusted source IP addresses or ranges that are allowed to access the management server.
      //     sourceAddressPrefixes: [ '${allowedIPAddresses[0]}/32' ]
      //     // destinationAddressPrefixes: Specifies the destination IP addresses or ranges for the traffic. In this case, it is set to '10.20.20.0/24', which represents the IP address range of the management subnet.
      //     destinationAddressPrefix: 'VirtualNetwork' // Assuming we want to restrict access to the virtual network

      //   }
      // }
      // {
      //   name: 'specific-inbound-allow'
      //   properties: {
      //     priority: 200
      //     direction: 'Inbound'
      //     access: 'Allow'
      //     protocol: '*'
      //     sourceAddressPrefix: '${allowedIPAddresses[0]}/32'
      //     destinationAddressPrefix: '*'
      //     sourcePortRange: '*'
      //     destinationPortRange: '*'
      //     description: 'Allow specific IP address'
      //   }
      // }

      // // destinationAddressPrefix: 'VirtualNetwork' // Assuming you want to restrict access to the virtual network

      // {
      //   name: 'specific-outbound-allow'
      //   properties: {
      //     priority: 200
      //     direction: 'Outbound'
      //     access: 'Allow'
      //     protocol: '*'
      //     sourceAddressPrefix: '${allowedIPAddresses[0]}/32'
      //     destinationAddressPrefix: '*'
      //     sourcePortRange: '*'
      //     destinationPortRange: '*'
      //     description: 'Allow specific IP address'
      //   }
      // }
      {
        name: 'SSH-rule'
        properties: {
          protocol: 'TCP'
          sourceAddressPrefix: '${allowedIPAddresses[0]}/32'
          destinationAddressPrefix: '*'
          sourcePortRange: '*'
          destinationPortRange: '22'
          access: 'Allow'
          priority: 1000
          direction: 'Inbound'
        }
      }
      {
        name: 'RDP-rule'
        properties: {
          protocol: 'TCP'
          sourceAddressPrefix: '${allowedIPAddresses[0]}/32'
          destinationAddressPrefix: '*'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          access: 'Allow'
          priority: 1100
          direction: 'Inbound'
        }
      }
    ]
  }
}

/* -------------------------------------------------------------------------- */
/*                     Public IP                                              */
/* -------------------------------------------------------------------------- */
// managementPublicIP: The management public IP resource is created next. It provides a 
// public IP address for the management server, allowing it to be accessible from the internet. 
// Public IP resource does not have any dependencies on other resources.

resource managementPublicIP 'Microsoft.Network/publicIPAddresses@2022-11-01' = {
  name: publicIpName
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
    // dnsSettings: {
    //   domainNameLabel: DNSdomainNameLabel
    // }
  }
}

/* -------------------------------------------------------------------------- */
/*                     Network Interface Card                                 */
/* -------------------------------------------------------------------------- */
// managementNetworkInterface: The management network interface is defined next. It depends on the 
// managementNSG because it needs the NSG's configuration to associate the security rules with the 
// network interface. By placing the network interface definition here, we ensure that the NSG is created
//  and its properties are accessible.

// The network interface is responsible for connecting the resource to the VNet and a specific subnet within the VNet.

// Dependencies: Public IP

resource managementNetworkInterface 'Microsoft.Network/networkInterfaces@2022-11-01' = {
  name: nicName
  location: location
  // dependsOn: [
  //   nsgManagement
  // ]
  properties: {
    ipConfigurations: [
      {
        name: IPConfigName
        properties: {
          subnet: {
            // The ID is written like this because I wrote down the subnet inside the vnet
            id: '${vnetManagement.id}/subnets/${subnetName}'
          }
          privateIPAddress: '10.20.20.10'
          privateIPAddressVersion: 'IPv4'
          privateIPAllocationMethod: 'Static'
          publicIPAddress: {
            id: managementPublicIP.id
          }
        }
      }
    ]
  }
}

/* -------------------------------------------------------------------------- */
/*                     PEERING                                                */
/* -------------------------------------------------------------------------- */
// peering: To connect the VNet for management server and the VNet for application, we can establish VNet peering.
// VNet peering enables virtual machines and other resources in one VNet to communicate with resources in the peered VNet, 
// as if they were part of the same network.

// ToDo: VnetPeering to connect this management vnet to the app vnet

resource vnetmngntvnetwebapp 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-11-01' = {
  parent: vnetManagement
  name: '${virtualNetworkName}-to-${virtualNetworkName_webapp}'
  properties: {
    remoteVirtualNetwork: {
      id: vnetWebApp.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
  }
}

// // /* -------------------------------------------------------------------------- */
// // /*                     STORAGE                                                */
// // /* -------------------------------------------------------------------------- */

// // ToDo: How to dynamically create a name without hard coding
// param storageAccountPrefix string = 'storage'
// param storageAccountName string = '${storageAccountPrefix}${uniqueString(resourceGroup().id)}'

// resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
//   name: storageAccountName
//   location: location
//   sku: {
//     name: 'Standard_LRS'
//   }
//   kind: 'StorageV2'
//   properties: {
//     supportsHttpsTrafficOnly: true
//     encryption: {
//       services: {
//         file: {
//           enabled: true
//         }
//         blob: {
//           enabled: true
//         }
//       }
//       keySource: 'Microsoft.Storage'
//     }
//     networkAcls: {
//       defaultAction: 'Deny'
//       bypass: 'AzureServices'
//     }
//   }
// }

// // /* -------------------------------------------------------------------------- */
// // /*                     CONTAINER                                              */
// // /* -------------------------------------------------------------------------- */

// // ToDo: How to dynamically create a name without hard coding
// param containerNamePrefix string = 'container'
// param containerName string = '${containerNamePrefix}${uniqueString(resourceGroup().id)}'

// resource storageContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01' = {
//   name: '${storageAccountName}/default/${containerName}'
//   properties: {
//     // Deze script moeten niet publiekelijk toegankelijk zijn.
//     publicAccess: 'None'
//   }
//   dependsOn: [
//     storageAccount
//   ]
// }

// output storageAccountConnectionString string = storageAccount.properties.primaryEndpoints.blob
// output storageContainerUrl string = storageContainer.properties.publicAccess

// /* -------------------------------------------------------------------------- */
// /*                     STORAGE                                                */
// /* -------------------------------------------------------------------------- */

// ToDo: How to dynamically create a name without hard coding
param storageAccountPrefix string = 'storage'
param storageAccountName string = '${storageAccountPrefix}${uniqueString(resourceGroup().id)}'

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        file: {
          enabled: true
        }
        blob: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
  }
}

// /* -------------------------------------------------------------------------- */
// /*                     CONTAINER                                              */
// /* -------------------------------------------------------------------------- */

// ToDo: How to dynamically create a name without hard coding
param containerNamePrefix string = 'container'
param containerName string = '${containerNamePrefix}${uniqueString(resourceGroup().id)}'

resource storageContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01' = {
  name: '${storageAccountName}/default/${containerName}'
  properties: {
    // Deze script moeten niet publiekelijk toegankelijk zijn.
    publicAccess: 'None'
  }
  dependsOn: [
    storageAccount
  ]
}

// /* -------------------------------------------------------------------------- */
// /*                     OUTPUT - STORAGE & CONTAINER                           */
// /* -------------------------------------------------------------------------- */

output storageAccountName string = storageAccount.name
output storageAccountID string = storageAccount.id
output storageAccountConnectionStringBlobEndpoint string = storageAccount.properties.primaryEndpoints.blob

output storageContainerName string = storageContainer.name
output storageContainerID string = storageContainer.id
output storageContainerUrl string = storageContainer.properties.publicAccess

/* -------------------------------------------------------------------------- */
/*                     Virtual Machine / Server                               */
/* -------------------------------------------------------------------------- */
// managementVirtualMachine: Finally, the management virtual machine resource is defined. It depends on 
// the managementNetworkInterface because it requires a network interface to be associated with the virtual 
// machine. By placing the virtual machine definition last, we ensure that all the necessary dependencies, 
// such as the network interface, NSG, and subnet, are created and available.

// ToDo: Management server is a WINDOWS SERVER
// ToDo: Web server is a a LINUX SERVER
// ToDo: Make a key vault first for the 'All VM disks must be encrypted.'
// ToDo: Connect Availability Set resource

var storageAccountConnectionStringBlobEndpoint = storageAccount.properties.primaryEndpoints.blob

@secure()
@description('The administrator username.')
param adminUsername string

@secure()
@description('The administrator password.')
param adminPassword string

var virtualMachineName_mngt = 'vmmanagement'
var virtualMachineSize_mngt = 'Standard_B1ms'
// var virtualMachineSize_mngt = 'Standard_B2s'
var virtualMachineOSVersion_mngt = '2022-Datacenter'

resource VMmanagement 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: virtualMachineName_mngt
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: virtualMachineSize_mngt
    }
    osProfile: {
      computerName: virtualMachineName_mngt
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: virtualMachineOSVersion_mngt
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
          // ToDo: Encrypt the disk
          // diskEncryptionSet: {
          //   id: diskEncryptionSet.id
          // }
        }
      }
      dataDisks: [
        {
          diskSizeGB: 256
          lun: 0
          createOption: 'Empty'
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: managementNetworkInterface.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: storageAccountConnectionStringBlobEndpoint
      }
    }
  }
}

/* -------------------------------------------------------------------------- */
/*                     Output                                                 */
/* -------------------------------------------------------------------------- */

output VMmanagementName string = VMmanagement.name
output VMmanagementID string = VMmanagement.id

/* -------------------------------------------------------------------------- */
/* -------------------------------------------------------------------------- */
/* -------------------------------------------------------------------------- */
/* -------------------------------------------------------------------------- */
/* -------------------------------------------------------------------------- */
/* -------------------------------------------------------------------------- */
/* -------------------------------------------------------------------------- */
/*                              WEB APP                                       */
/* -------------------------------------------------------------------------- */

// ToDo:
//  - Adjust this according to requirements

// Management Server: 10.20.20.0/24
// Web/App Server: 10.10.10.0/24

/* -------------------------------------------------------------------------- */
/*                     PARAMS & VARS                                          */
/* -------------------------------------------------------------------------- */

// vnet
var virtualNetworkName_webapp = 'webapp-vnet'
// subnet
var subnetName_webapp = 'webapp-subnet'
// nsg
var nsgName_webapp = 'webapp-nsg'
// public ip
var publicIpName_webapp = 'webapp-public-ip'
// nic
var nicName_webapp = 'webapp-nic'
// addressPrefixes
var vnet_addressPrefixes_webapp = '10.10.10.0/24'
// // DNS
// var DNSdomainNameLabel_webapp = 'webapp-server'
// IP config
var IPConfigName_webapp = 'webapp-ipconfig'

/* -------------------------------------------------------------------------- */
/*                     Virtual Network with subnet                            */
/* -------------------------------------------------------------------------- */
// In Azure, a Virtual Network (VNet) is a fundamental networking construct that enables 
// you to securely connect and isolate Azure resources, such as virtual machines (VMs), virtual 
// machine scale sets, and other services. A VNet acts as a virtual representation of a 
// traditional network, allowing you to define IP address ranges, subnets, and network security policies.

// Dependencies: Azure Subscription, Azure Resource Group, Azure Region, Address Space, Subnets, Network Security Groups (NSGs)
// Additional: VnetPeering to connect this management vnet to the app vnet for later

// This creates a virtual network for the management side
// I've created a separate vnet for the management side to isolate it from the other cloud infrastracture
// This segregation helps improve security and network performance by controlling traffic flow between resources.
// Within VNet, I created a subnet to further segment the resources inside the vnet like virtual machine for the server

resource vnetWebApp 'Microsoft.Network/virtualNetworks@2022-11-01' = {
  name: virtualNetworkName_webapp
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnet_addressPrefixes_webapp
      ]
    }
    // I wrote the subnet inside vnet because of best practice

    // managementSubnet: The management subnet is defined first as it serves as the foundational 
    // component for the other resources. It specifies the address prefix for the subnet where the 
    // management server will be deployed.
    subnets: [
      {
        name: subnetName_webapp
        properties: {
          addressPrefix: vnet_addressPrefixes_webapp
          // By associating an NSG with a subnet, we can enforce network-level security policies for the resources within that subnet.
          networkSecurityGroup: {
            id: resourceId('Microsoft.Network/networkSecurityGroups', nsgName_webapp)
          }
          // serviceEndpoints: [
          //   // Add service endpoints if required
          // ]
          // // ToDo: Check the requirements if delegation is needed
          // delegation: {
          //   name: 'delegation'
          //   properties: {
          //     serviceName: 'Microsoft.Authorization/roleAssignments'
          //   }
        }
      }
    ]
  }
}

/* -------------------------------------------------------------------------- */
/*                     Output                                                 */
/* -------------------------------------------------------------------------- */
// ToDo:
// - add output from other resources

output vnetWebAppName string = vnetWebApp.name
output vnetWebAppID string = vnetWebApp.id
output WebAppSubnetID string = vnetWebApp.properties.subnets[0].id

/* -------------------------------------------------------------------------- */
/*                     Network Security Group                                 */
/* -------------------------------------------------------------------------- */

resource nsgWebApp 'Microsoft.Network/networkSecurityGroups@2022-11-01' = {
  name: nsgName_webapp
  location: location
  // Contains the set of properties for the NSG, including the security rules.
  properties: {
    // security Rule are An array of security rules that define the network traffic rules for the NSG.
    securityRules: [
      // {
      //   name: securityRulesName_webapp
      //   properties: {
      //     // priority: Lower values indicate higher priority. In this case, the rule has a priority of 100.
      //     priority: 100
      //     access: 'Allow'
      //     // direction: Indicates the direction of the traffic. 'Inbound' means the rule applies to incoming traffic.
      //     direction: 'Inbound'
      //     protocol: 'Tcp'
      //     sourcePortRange: '*'
      //     // destinationPortRange: Specifies the destination port range for the traffic. In this example, it is set to '22', which is the default port for SSH
      //     // should it be '3389'
      //     destinationPortRange: '22' // Customize for SSH or RDP port
      //     // sourceAddressPrefixes: Defines the source IP addresses or ranges allowed for the traffic. You can add trusted source IP addresses or ranges that are allowed to access the management server.
      //     sourceAddressPrefixes: [
      //       // Add trusted source IP addresses/ranges
      //       // '10.20.20.0/24'
      //       // '10.10.10.0/24'
      //       '85.149.106.77'
      //     ]
      //     // destinationAddressPrefixes: Specifies the destination IP addresses or ranges for the traffic. In this case, it is set to '10.20.20.0/24', which represents the IP address range of the management subnet.
      //     destinationAddressPrefixes: [
      //       // Customize for management subnet address range
      //       vnet_addressPrefixes_webapp
      //     ]
      //   }
      // }
      // Add additional security rules as needed
      // {
      //   name: 'specific-inbound-allow'
      //   properties: {
      //     priority: 200
      //     direction: 'Inbound'
      //     access: 'Allow'
      //     protocol: '*'
      //     sourceAddressPrefix: '${allowedIPAddresses[0]}/32'
      //     destinationAddressPrefix: '*'
      //     sourcePortRange: '*'
      //     destinationPortRange: '*'
      //     description: 'Allow specific IP address'
      //   }
      // }

      // // destinationAddressPrefix: 'VirtualNetwork' // Assuming you want to restrict access to the virtual network

      // {
      //   name: 'specific-outbound-allow'
      //   properties: {
      //     priority: 200
      //     direction: 'Outbound'
      //     access: 'Allow'
      //     protocol: '*'
      //     sourceAddressPrefix: '${allowedIPAddresses[0]}/32'
      //     destinationAddressPrefix: '*'
      //     sourcePortRange: '*'
      //     destinationPortRange: '*'
      //     description: 'Allow specific IP address'
      //   }
      // }
      {
        name: 'HTTPS-rule'
        properties: {
          protocol: 'TCP'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          sourcePortRange: '*'
          destinationPortRange: '443'
          access: 'Allow'
          priority: 1000
          direction: 'Inbound'
        }
      }
      {
        name: 'HTTP-rule'
        properties: {
          protocol: 'TCP'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          sourcePortRange: '*'
          destinationPortRange: '80'
          access: 'Allow'
          priority: 1080
          direction: 'Inbound'
        }
      }
      // Web/App Server: 10.10.10.0/24
      {
        name: 'SSH-rule'
        properties: {
          protocol: 'TCP'
          sourceAddressPrefix: '10.10.10.10/32'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
          access: 'Allow'
          priority: 1200
          direction: 'Inbound'
        }
      }
    ]
  }
}

output nsgWebAppID string = nsgWebApp.id
output nsgWebAppName string = nsgWebApp.name

/* -------------------------------------------------------------------------- */
/*                     Public IP                                              */
/* -------------------------------------------------------------------------- */
// managementPublicIP: The management public IP resource is created next. It provides a 
// public IP address for the management server, allowing it to be accessible from the internet. 
// Public IP resource does not have any dependencies on other resources.

resource WebAppPublicIP 'Microsoft.Network/publicIPAddresses@2022-11-01' = {
  name: publicIpName_webapp
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
    // dnsSettings: {
    //   domainNameLabel: DNSdomainNameLabel_webapp
    // }
  }
}

output WebAppPublicIPName string = WebAppPublicIP.name
output WebAppPublicIPID string = WebAppPublicIP.id

output webAppPublicIpAddress string = WebAppPublicIP.properties.ipAddress
output webAppDnsDomainNameLabel string = WebAppPublicIP.properties.dnsSettings.domainNameLabel

/* -------------------------------------------------------------------------- */
/*                     Network Interface Card                                 */
/* -------------------------------------------------------------------------- */
// managementNetworkInterface: The management network interface is defined next. It depends on the 
// managementNSG because it needs the NSG's configuration to associate the security rules with the 
// network interface. By placing the network interface definition here, we ensure that the NSG is created
//  and its properties are accessible.

// The network interface is responsible for connecting the resource to the VNet and a specific subnet within the VNet.

resource WebAppNetworkInterface 'Microsoft.Network/networkInterfaces@2022-11-01' = {
  name: nicName_webapp
  location: location
  dependsOn: [
    nsgWebApp
  ]
  properties: {
    ipConfigurations: [
      {
        name: IPConfigName_webapp
        properties: {
          subnet: {
            // The ID is written like this because I wrote down the subnet inside the vnet
            id: '${vnetWebApp.id}/subnets/${subnetName_webapp}'
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: WebAppPublicIP.id
          }
        }
      }
    ]
  }
}

output nic_webappID string = WebAppNetworkInterface.id

/* -------------------------------------------------------------------------- */
/*                     PEERING                                                */
/* -------------------------------------------------------------------------- */
// peering: To connect the VNet for management server and the VNet for application, we can establish VNet peering.
// VNet peering enables virtual machines and other resources in one VNet to communicate with resources in the peered VNet, 
// as if they were part of the same network.

// ToDo: VnetPeering to connect this webapp vnet to the management vnet

resource vnetwebappvnetmngnt 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-11-01' = {
  parent: vnetWebApp
  name: '${virtualNetworkName_webapp}-${virtualNetworkName}'
  properties: {
    remoteVirtualNetwork: {
      id: vnetManagement.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
  }
}

output vnetWebAppVnetMngnPEERINGId string = vnetwebappvnetmngnt.id

/* -------------------------------------------------------------------------- */
/*                     Virtual Machine / Server                               */
/* -------------------------------------------------------------------------- */
// managementVirtualMachine: Finally, the management virtual machine resource is defined. It depends on 
// the managementNetworkInterface because it requires a network interface to be associated with the virtual 
// machine. By placing the virtual machine definition last, we ensure that all the necessary dependencies, 
// such as the network interface, NSG, and subnet, are created and available.

// ToDo: Management server is a WINDOWS SERVER
// ToDo: Web server is a a LINUX SERVER
// ToDo: Make a key vault first for the 'All VM disks must be encrypted.'
// ToDo: Connect Availability Set resource
// resource VMManagement 'Microsoft.Compute/virtualMachines@2023-03-01' = {
//   name: 
//   location: 
// }

/* -------------------------------------------------------------------------- */
/*                              Key Vault                                     */
/* -------------------------------------------------------------------------- */

var keyVaultName = 'mykeyvault${uniqueString(resourceGroup().id)}'

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: keyVaultName
  // Find out if this key vault should be a child of other resources
  // parent:
  location: location
  properties: {
    // stock-keeping unit refers to the pricing tier or level of service for the Key Vault instance.
    sku: {
      family: 'A'
      // 'standard' SKU is typically more cost-effective compared to higher-tier SKUs. If budget is a consideration and the desired features of the 'standard' SKU meet the project's requirements, it can be a suitable choice.
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enabledForDeployment: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    // enablePurgeProtection: false
    enabledForTemplateDeployment: true
    createMode: 'default'
    // enableRbacAuthorization: true
    // publicNetworkAccess: 'disabled'
    accessPolicies: [
      {
        objectId: 'ade71768-d55d-4d4f-a5b1-5d058c571459'
        tenantId: subscription().tenantId
        permissions: {
          keys: [
            'all'
          ]
        }
      }
    ]
  }
}

/* -------------------------------------------------------------------------- */
/*                              OUTPUT KEY VAULT                              */
/* -------------------------------------------------------------------------- */

output keyVaultName string = keyVaultName
output keyVaultID string = keyVault.id
output keyVaultURI string = keyVault.properties.vaultUri

/* -------------------------------------------------------------------------- */
/*                              Key Vault Key                                 */
/* -------------------------------------------------------------------------- */

// Reference: https://learn.microsoft.com/en-us/azure/templates/microsoft.keyvault/vaults/keys?pivots=deployment-language-bicep#keyattributes

resource keyKeyVault 'Microsoft.KeyVault/vaults/keys@2022-07-01' = {
  name: 'keyVaultKey'
  parent: keyVault
  properties: {
    attributes: {
      enabled: true
    }
    keySize: 2048 // For example: 2048, 3072, or 4096 for RSA.
    kty: 'RSA'
  }
}

/* -------------------------------------------------------------------------- */
/*                              OUTPUT KEY                                    */
/* -------------------------------------------------------------------------- */

output keyKeyVaultID string = keyKeyVault.id
output keyKeyVaultName string = keyKeyVault.name

/* -------------------------------------------------------------------------- */
/*                              DOCUMENTATION                                 */
/* -------------------------------------------------------------------------- */

// Parameters:

// - adminUsername: The username for the admin account.
// - adminPassword: The password for the admin account.
// - vmNamePrefix: The prefix to use for VM names.
// - location: The location for all resources.
// - vmSize: The size of the virtual machines.

// Variables:

// - availabilitySetName: The name of the availability set.
// - storageAccountType: The type of the storage account.
// - storageAccountName: The name of the storage account.
// - virtualNetworkName: The name of the virtual network.
// - subnetName: The name of the backend subnet.
// - loadBalancerName: The name of the internal load balancer.
// - networkInterfaceName: The name of the network interface.
// - subnetRef: The reference to the subnet.
// - numberOfInstances: The number of VM instances.

// Resources:

// - storageAccount: Deploys a storage account for VM disks and backups.
// - availabilitySet: Deploys an availability set for high availability and fault tolerance.
// - virtualNetwork: Deploys a virtual network for network isolation.
// - subnetManagement: Deploys a subnet for the management server.
// - subnetApplication: Deploys a subnet for the application server.
// - nsgManagementSubnet: Deploys a network security group for the management subnet.
// - nsgApplicationSubnet: Deploys a network security group for the application subnet.
// - networkInterface: Deploys network interfaces for the VM instances.
// - loadBalancer: Deploys an internal load balancer for traffic distribution.
// - vm: Deploys the virtual machines.

// Additional resources:

// - publicIPAddress: Deploys a public IP address for the management server.
// - managementNetworkInterface: Deploys a network interface for the management server.
// - managementNsgRuleSSH: Configures an NSG rule to allow SSH access to the management server.
// - managementNsgRuleRDP: Configures an NSG rule to allow RDP access to the management server.
// - bootstrapStorageAccount: Deploys a storage account to store bootstrap and post-deployment scripts.
// - backupSolution: Deploys the backup solution for the VMs.

// # Deployment Outputs and Artifacts

// Explain the outputs of the infrastructure deployment, such as resource group details, resource URIs, or connection strings.
// Document any artifacts generated during the deployment process (e.g., ARM templates).
// Describe how to access or use the deployed resources.
