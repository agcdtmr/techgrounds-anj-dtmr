//  Use this command to deploy
// az group create --name RGTestVnetManagement --location westeurope
// az deployment group create --resource-group RGTestVnetManagement --template-file vnetmanagement.bicep

@description('Admin username')
param adminUsername string

@description('Admin password')
@secure()
param adminPassword string

@description('Location for all resources.')
param location string = resourceGroup().location

var virtualNetworkName = 'vNetManagement'
var subnetName = 'SubnetManagement'

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-11-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.0.2.0/24'
        }
      }
    ]
  }
}

// ToDo:
//  - Adjust this according to requirements
