param appServicePlanId string
param environment string
param storageAccountName string
param appInsightsInstrumentationKey string
param appInsightsConnectionString string
param location string
param serviceBusNamespace string
param serviceBusQueueName string
param allowedSubnetId string
param appGatewayPublicIp string
param appServiceFunctionManagedIdentityName string

resource appServiceFunctionManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: appServiceFunctionManagedIdentityName
}
resource functionApp 'Microsoft.Web/sites@2021-02-01' = {
  name: 'yakshop-function-app-${environment}'
  location: location
  kind: 'functionapp,linux'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${appServiceFunctionManagedIdentity.id}': {}
    }
  }
  properties: {
    serverFarmId: appServicePlanId
    httpsOnly: true
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=<your_account_key>;EndpointSuffix=core.windows.net'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY' // Sends logs to Application Insights
          value: appInsightsInstrumentationKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
        {
          name: 'ServiceBusConnection__fullyQualifiedNamespace'
          value: '${serviceBusNamespace}.servicebus.windows.net'
        }
        {
          name: 'Yakshop-order-queue' // if we want to make asynchronous queue to process orders made in the web shop.
          value: serviceBusQueueName
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
}

