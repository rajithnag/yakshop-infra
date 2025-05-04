param location string
param environment string
param systemCode string

var preExistingMicrosoftRoles = {
  KeyVaultReader: '21090545-7ca7-4776-b22c-e363652d74d2'
  KeyVaultCryptoServiceEncryptionUser: 'e147488a-f6f5-4113-8e2d-b22465e65bf6'
}

resource keyVaultReadAccessRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: preExistingMicrosoftRoles.KeyVaultReader
}

resource keyVaultCryptoServiceEncryptionUserRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: preExistingMicrosoftRoles.KeyVaultCryptoServiceEncryptionUser
}

var functionAppManagedIdentityName = '${systemCode}-${environment}-functionapp-managed-identity'

resource functionAppManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: functionAppManagedIdentityName
  location: location
}

resource functionAppKeyVaultReaderAccess 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('${functionAppManagedIdentityName}-keyvault-access')
  properties: {
    roleDefinitionId: keyVaultReadAccessRole.id
    principalId: functionAppManagedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource functionAppKeyVaultEncryptionUser 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('${functionAppManagedIdentityName}-keyvault-encryption-user-access', environment)
  properties: {
    roleDefinitionId: keyVaultCryptoServiceEncryptionUserRole.id
    principalId: functionAppManagedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

output functionAppManagedIdentityName string = functionAppManagedIdentity.name
output functionAppManagedIdentityObjectId string = functionAppManagedIdentity.properties.principalId
output functionAppKeyVaultReaderAccessId string = functionAppKeyVaultReaderAccess.id
output functionAppKeyVaultEncryptionUserAccessId string = functionAppKeyVaultEncryptionUser.id
