param location string
param environment string
param gatewaySubnetId string
param sslCertificate string
param appGatewayManagedIdentityName string
var isProd = (environment == 'prd') // Check if the environment is production so we can use lower configs for non-prod environments


resource appGatewayManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: appGatewayManagedIdentityName
}

resource apim 'Microsoft.ApiManagement/service@2022-08-01' = {
  name: 'yakshop-apim-${environment}'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${appGatewayManagedIdentity.id}': {}
    }
  }
  sku: {
    name: isProd ? 'Premium' : 'Developer' // Use Premium SKU for production and Developer SKU for non-production
    capacity: 1
  }
  properties: {
    publisherEmail: 'admin@yakshop.com'
    publisherName: 'Yakshop Admin'
    notificationSenderEmail: 'noreply@yakshop.com'
  }
}

resource publicIp 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: 'yakshop-public-ip-${environment}'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    dnsSettings: {
      domainNameLabel: 'yakshop-${environment}'
    }
  }
}

resource appGateway 'Microsoft.Network/applicationGateways@2021-02-01' = {
  name: 'yakshop-app-gateway-${environment}'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${appGatewayManagedIdentity.id}': {}
    }
  }
  properties: {
    sku: {
      name: 'WAF_V2' // WAF allows for web aplpication firewall features
      tier: 'WAF_V2'
    }
    gatewayIPConfigurations: [
      {
        name: 'AppGatewaySubnetConfig'
        properties: {
          subnet: {
            id: gatewaySubnetId
          }
        }
      }
    ]
    autoscaleConfiguration: {
      minCapacity: 1
      maxCapacity: 5
    }
    frontendIPConfigurations: [
      {
        name: 'frontendIPConfig'
        properties: {
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'frontendPort'
        properties: {
          port: 443
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'backendPool'
        properties: {
          backendAddresses: [
            {
              fqdn: 'yakshop-apim-${environment}.azure-api.net' // Connect to APIM so that APIM can route to the backend services
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'httpsSetting'
        properties: {
          port: 443
          protocol: 'Https'
          pickHostNameFromBackendAddress: true
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', 'yakshop-app-gateway-${environment}', 'apim-probe')
          }
        }
      }
    ]    
    httpListeners: [
      {
        name: 'DefaultHttpsListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', 'yakshop-app-gateway-${environment}', 'frontendIPConfig')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', 'yakshop-app-gateway-${environment}', 'frontendPort')
          }
          protocol: 'Https'
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', 'yakshop-app-gateway-${environment}', sslCertificate)
          }
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'rule'
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', 'yakshop-app-gateway-${environment}','DefaultHttpsListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', 'yakshop-app-gateway-${environment}', 'backendPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', 'yakshop-app-gateway-${environment}', 'httpsSetting')
          }          
        }
      }
    ]
    webApplicationFirewallConfiguration: {
      enabled: true
      firewallMode: 'Prevention'
      ruleSetType: 'OWASP'
      ruleSetVersion: '3.2'
    }
    probes: [
      {
        name: 'apim-probe'
        properties: {
          protocol: 'Https'
          host: 'yakshop-apim-${environment}.azure-api.net'
          path: '/health'
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          match: {
            statusCodes: ['200-399']
          }
        }
      }
    ]
  }
}

output publicIpAddress string = publicIp.properties.ipAddress
