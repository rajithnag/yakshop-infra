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

var webAppManagedIdentityName = '${systemCode}-${environment}-webapp-managed-identity'

resource webAppManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: webAppManagedIdentityName
  location: location
}

resource webAppKeyVaultReaderAccess 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('${webAppManagedIdentityName}-keyvault-access')
  properties: {
    roleDefinitionId: keyVaultReadAccessRole.id
    principalId: webAppManagedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource webAppKeyVaultEncryptionUser 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('${webAppManagedIdentityName}-keyvault-encryption-user-access', environment)
  properties: {
    roleDefinitionId: keyVaultCryptoServiceEncryptionUserRole.id
    principalId: webAppManagedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

output webAppManagedIdentityName string = webAppManagedIdentity.name
output webAppManagedIdentityObjectId string = webAppManagedIdentity.properties.principalId
output webAppKeyVaultReaderAccessId string = webAppKeyVaultReaderAccess.id
output webAppKeyVaultEncryptionUserAccessId string = webAppKeyVaultEncryptionUser.id


