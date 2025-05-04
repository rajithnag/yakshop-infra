param appServicePlanId string
param location string
param appInsightsInstrumentationKey string
param appInsightsConnectionString string
param environment string
param allowedSubnetId string
param appGatewayPublicIp string
param appServiceWebManagedIdentityName string 

resource appServiceWebManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: appServiceWebManagedIdentityName
}

// List of MicroServices for the YakShop Backend. This list can be extended when new microservices are added to the YakShop backend.
// Each microservice will be deployed as a separate Azure App Service.
var services = [
  'user'
  'product'
  'order'
  'payment'
]

resource webAppServices 'Microsoft.Web/sites@2022-03-01' = [for service in services: {
  name: 'yakshop-${service}-${environment}'
  location: location
  kind: 'app,linux'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${appServiceWebManagedIdentity.id}': {}
    }
  }
  properties: {
    httpsOnly: true
    vnetImagePullEnabled: true
    vnetRouteAllEnabled: true
    serverFarmId: appServicePlanId
    siteConfig: {
      alwaysOn: true
      healthCheckPath: '/health'
      linuxFxVersion: 'DOTNETCORE|9.0'
      appSettings: [
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsInstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
      ]
      ipSecurityRestrictions: [
        {
          name: 'AllowSubnet'
          priority: 100
          action: 'Allow'
          vnetSubnetResourceId: allowedSubnetId
          tag: 'Default'
        }
        {
          name: 'AllowAppGateway'
          priority: 110
          action: 'Allow'
          ipAddress: appGatewayPublicIp
          tag: 'Default'
        }
        {
          name: 'DenyAll'
          priority: 200
          action: 'Deny'
          ipAddress: '0.0.0.0/0'
          tag: 'Default'
        }
      ]
    }
  }
}]
