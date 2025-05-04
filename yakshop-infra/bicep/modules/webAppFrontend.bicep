param appServicePlanId string
param location string
param environment string
param appInsightsInstrumentationKey string
param appInsightsConnectionString string
param storageAccountName string
var isProd = (environment == 'prd')
param appServiceWebManagedIdentityName string 

resource appServiceWebManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: appServiceWebManagedIdentityName
}

resource webApp 'Microsoft.Web/sites@2022-03-01' = {
  name: 'yakshop-frontend-${environment}'
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
    serverFarmId: appServicePlanId
    siteConfig: {
      linuxFxVersion: 'NODE|18-lts'
      alwaysOn: true
      healthCheckPath: '/health'
      appSettings: [
        {
          name: 'NODE_ENV'
          value: isProd ? 'production': 'development'
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
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
          name: 'WEB_ASSETS_BASE_URL' // This variable can be used in the frontend code to access the blob storage
          value: 'https://${storageAccountName}.blob.${az.environment().suffixes.storage}/webAssetsContainer'
        }
      ]
    }
  }
}

