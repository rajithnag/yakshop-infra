param environment string
param location string

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: 'yakshop-vnet-${environment}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'appSubnet-${environment}'
        properties: {
          addressPrefix: '10.0.1.0/24'
          serviceEndpoints: [
            {
              service: 'Microsoft.Sql' // Service endpoint enables subnet to talk to Azure SQL over the Azure backend network, without exposing SQL to public IPs.
            }
          ]
        }
      }
      {
        name: 'databaseSubnet-${environment}' // This subnet is used for the SQL server private endpoint
        properties: {
          addressPrefix: '10.0.2.0/24'
        }
      }
      {
        name: 'gatewaySubnet-${environment}' // This subnet is used for the App Gateway and APIM
        properties: {
          addressPrefix: '10.0.3.0/24'
        }
      }
    ]
  }
}

output vnetId string = vnet.id
output appSubnetId string = '${vnet.id}/subnets/appSubnet-${environment}'
output databaseSubnetId string = '${vnet.id}/subnets/databaseSubnet-${environment}'
output gatewaySubnetId string = '${vnet.id}/subnets/gatewaySubnet-${environment}'
