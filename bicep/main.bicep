param environment string
param location string = resourceGroup().location

// Create Virtual Network and Subnets for the application.
module network 'modules/network.bicep' = {
  name: 'network'
  params: {
    environment: environment
    location: location
  }
}

// Create Managed Identities for the application components.
// These identities will be used to access other Azure resources securely without the need for credentials.
module managedIdentities 'modules/managed-identities.bicep' = {
  name: 'YakManagedIdentities'
  params: {
    location: location
    environment: environment
  }
}

// Create a Key Vault for storing keys, secrets and certificates so that they can be securely accessed by the application.
module keyVault 'modules/keyVault.bicep' = {
  name: 'keyVault'
  params: {
    environment: environment
    location: location
  }
}

// Create a Storage Account for storing application data, logs, and other files.
module storage 'modules/storage.bicep' = {
  name: 'storage'
  params: {
    environment: environment
    location: location
    encryptionKeyName: keyVault.outputs.storageAccountEncryptionKeyName
    keyvaultUri: keyVault.outputs.keyVaultUri
    storageAccountManagedIdentityName: managedIdentities.outputs.yakStorageAccountIdentityName
  }
}

// Create an Application Insights resource for monitoring and diagnostics of the application.
module appInsights 'modules/appInsights.bicep' = {
  name: 'appInsights'
  params: {
    environment: environment
    location: location
  }
}

// Create an API Management service for managing APIs and providing a gateway for the backend services.
// This service will be used to expose the APIs to external B2B customers and manage access to the APIs.
module apim 'modules/apim.bicep' = {
  name: 'apim'
  params: {
    gatewaySubnetId: network.outputs.gatewaySubnetId
    sslCertificate: 'yakshop-cert'
    environment: environment
    location: location
    appGatewayManagedIdentityName: managedIdentities.outputs.yakAppGatewayManagedIdentityName
  }
}

// Create an App Service Plan for hosting the Frontend and Backend web apps and Function App.
module appServicePlan 'modules/appServicePlan.bicep' = {
  name: 'appServicePlan'
  params: {
    location: location
    environment: environment
  }
}

// Create a Service Bus for asynchronous activities and communication between the different components of the application.
module serviceBus 'modules/serviceBus.bicep' = {
  name: 'serviceBus'
  params: {
    environment: environment
    location: location
    encryptionKeyName: keyVault.outputs.serviceBusEncryptionKeyName
    keyvaultUri: keyVault.outputs.keyVaultUri
    serviceBusManagedIdentityName: managedIdentities.outputs.yakServiceBusManagedIdentityName
  }
}

// Website hosted in Azure App Service
module webAppFrontend 'modules/webAppFrontend.bicep' = {
  name: 'webAppFrontend'
  params: {
    appServicePlanId: appServicePlan.outputs.appServicePlanId
    environment: environment
    appInsightsConnectionString: appInsights.outputs.appInsightsConnectionString
    appInsightsInstrumentationKey: appInsights.outputs.appInsightsInstrumentationKey
    location: location
    storageAccountName: storage.outputs.storageAccountName
    appServiceWebManagedIdentityName: managedIdentities.outputs.yakAppServiceWebAppIdentityName
  }
}

// Backend API hosted in Azure App Service as micoservices.
module webAppBackend 'modules/webAppBackend.bicep' = {
  name: 'webAppBackend'
  params: {
    appServicePlanId: appServicePlan.outputs.appServicePlanId
    environment: environment
    appInsightsConnectionString: appInsights.outputs.appInsightsConnectionString
    appInsightsInstrumentationKey: appInsights.outputs.appInsightsInstrumentationKey
    location: location
    allowedSubnetId: network.outputs.appSubnetId // Allow requests from app subnet
    appGatewayPublicIp: apim.outputs.publicIpAddress // Allow App Gateway to access the backend
    appServiceWebManagedIdentityName: managedIdentities.outputs.yakAppServiceWebAppIdentityName
  }
}

// Function App for handling background tasks and any other backend processing.
module functionApp 'modules/functionApp.bicep' = {
  name: 'functionApp'
  params: {
    appServicePlanId: appServicePlan.outputs.appServicePlanId
    storageAccountName: storage.outputs.storageAccountName
    environment: environment
    appInsightsConnectionString: appInsights.outputs.appInsightsConnectionString
    appInsightsInstrumentationKey: appInsights.outputs.appInsightsInstrumentationKey
    location: location
    serviceBusNamespace: serviceBus.outputs.serviceBusNamespaceName
    serviceBusQueueName: serviceBus.outputs.serviceBusQueueName
    allowedSubnetId: network.outputs.appSubnetId // Allow requests from app subnet
    appGatewayPublicIp: apim.outputs.publicIpAddress // Allow App Gateway to access the backend
    appServiceFunctionManagedIdentityName: managedIdentities.outputs.yakAppServiceFunctionAppIdentityName
  }
}

// Create an Azure SQL Database for storing relational data for the application.
// This database will be accessed by the backend API and Function App.
module sqlDatabase 'modules/sqlDatabase.bicep' = {
  name: 'sqlDatabase'
  params: {
    environment: environment
    location: location
    keyVaultName: keyVault.outputs.keyVaultName
    databaseSubnetId: network.outputs.databaseSubnetId
    appSubnetId: network.outputs.appSubnetId
    sqlDbManagedIdentityName: managedIdentities.outputs.yakSqlDBManagedIdentityName
  }
}

//Create seperate monitoring alerts for each backend service.
// We can extend this to include other apps and resources in the future.
module monitoringAlerts 'modules/monitoring-alerts.bicep' = {
  name: 'monitoring-alerts'
  params: {
    environment: environment
    backendServices: [
      'yakshop-user-${environment}'
      'yakshop-product-${environment}'
      'yakshop-order-${environment}'
      'yakshop-payment-${environment}'
    ]
  }
}
