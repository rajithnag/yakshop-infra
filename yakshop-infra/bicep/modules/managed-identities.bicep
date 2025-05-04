param location string
param environment string
param systemCode string = 'yak'


module yakSqlDbIdentity './managed-identities/sql-db-identity.bicep' = {
  name: 'YakSqlDbIdentity'
  params: {
    systemCode: systemCode
    environment: environment
    location: location
  }
}

module yakAppGatewayIdentity 'managed-identities/app-gateway-identity.bicep' = {
  name: 'YakAppGatewayIdentity'
  params: {
    location: location
    environment: environment
    systemCode: systemCode
  }
}

module serviceBusIdentity './managed-identities/service-bus-identity.bicep' = {
  name: 'ServiceBusIdentity'
  params: {
    location: location
    environment: environment
    systemCode: systemCode
  }
}

module storageAccountIdentity './managed-identities/storage-account-identity.bicep' = {
  name: 'StorageAccountIdentity'
  params: {
    location: location
    environment: environment
    systemCode: systemCode
  }
}

module appServiceWebAppIdentity './managed-identities/app-service-web-app-identity.bicep' = {
  name: 'AppServiceWebAppIdentity'
  params: {
    location: location
    environment: environment
    systemCode: systemCode
  }
}

module appServiceFunctionAppIdentity './managed-identities/app-service-function-app-identity.bicep' = {
  name: 'AppServiceFunctionAppIdentity'
  params: {
    location: location
    environment: environment
    systemCode: systemCode
  }
}

output yakSqlDBManagedIdentityName string = yakSqlDbIdentity.outputs.yakSqlDbIdentityName
output yakSqlDBManagedIdentityObjectId string = yakSqlDbIdentity.outputs.yakSqlDbIdentityObjectId

output yakAppGatewayManagedIdentityName string = yakAppGatewayIdentity.outputs.appGatewayManagedIdentityName
output yakAppGatewayManagedIdentityObjectId string = yakAppGatewayIdentity.outputs.appGatewayManagedIdentityObjectId

output yakServiceBusManagedIdentityName string = serviceBusIdentity.outputs.serviceBusManagedIdentityName
output yakServiceBusManagedIdentityObjectId string = serviceBusIdentity.outputs.serviceBusManagedIdentityObjectId

output yakStorageAccountIdentityName string = storageAccountIdentity.outputs.storageAccountManagedIdentityName
output yakStorageAccountIdentityObjectId string = storageAccountIdentity.outputs.storageAccountManagedIdentityObjectId

output yakAppServiceWebAppIdentityName string = appServiceWebAppIdentity.outputs.webAppManagedIdentityName
output yakAppServiceWebAppIdentityObjectId string = appServiceWebAppIdentity.outputs.webAppManagedIdentityObjectId

output yakAppServiceFunctionAppIdentityName string = appServiceFunctionAppIdentity.outputs.functionAppManagedIdentityName
output yakAppServiceFunctionAppIdentityObjectId string = appServiceFunctionAppIdentity.outputs.functionAppManagedIdentityObjectId
