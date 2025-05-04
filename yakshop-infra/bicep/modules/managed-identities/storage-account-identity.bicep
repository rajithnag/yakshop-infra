param location string


@allowed(['dev', 'tst', 'acc', 'prd'])
param environment string


param systemCode string

var preExistingMicrosoftRoles = {
  KeyVaultReader: '21090545-7ca7-4776-b22c-e363652d74d2'
  KeyVaultCryptoServiceEncryptionUser: 'e147488a-f6f5-4113-8e2d-b22465e65bf6'
}


resource keyVaultReadAccessRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: preExistingMicrosoftRoles.KeyVaultReader
}

resource KeyVaultCryptoServiceEncryptionUserRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: preExistingMicrosoftRoles.KeyVaultCryptoServiceEncryptionUser
}

var storageAccountManagedIdentityName = '${systemCode}-${environment}-storage-account-managed-identity'

resource storageAccountManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: storageAccountManagedIdentityName
  location: location
}

resource storageAccountKeyVaultReaderAccess 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('${storageAccountManagedIdentityName}-keyvault-access')
  properties: {
    roleDefinitionId: keyVaultReadAccessRole.id
    principalId: storageAccountManagedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource storageAccountKeyVaultEncryptionUser 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('${storageAccountManagedIdentityName}-keyvault-encryption-user-access', environment)
  properties: {
    roleDefinitionId: KeyVaultCryptoServiceEncryptionUserRole.id
    principalId: storageAccountManagedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

output storageAccountManagedIdentityName string = storageAccountManagedIdentity.name
output storageAccountManagedIdentityObjectId string = storageAccountManagedIdentity.properties.principalId

output storageAccountKeyVaultReaderAccessId string = storageAccountKeyVaultReaderAccess.id
output storageAccountKeyVaultEncryptionUserAccessId string = storageAccountKeyVaultEncryptionUser.id
