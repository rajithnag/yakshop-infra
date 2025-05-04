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

resource KeyVaultCryptoServiceEncryptionUserRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: preExistingMicrosoftRoles.KeyVaultCryptoServiceEncryptionUser
}

var serviceBusManagedIdentityName = '${systemCode}-${environment}-service-bus-managed-identity'

resource serviceBusManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: serviceBusManagedIdentityName
  location: location
}

resource serviceBusKeyVaultReaderAccess 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('${serviceBusManagedIdentityName}-keyvault-access')
  properties: {
    roleDefinitionId: keyVaultReadAccessRole.id
    principalId: serviceBusManagedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource serviceBusKeyVaultEncryptionUser 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('${serviceBusManagedIdentityName}-keyvault-encryption-user-access', environment)
  properties: {
    roleDefinitionId: KeyVaultCryptoServiceEncryptionUserRole.id
    principalId: serviceBusManagedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

output serviceBusManagedIdentityName string = serviceBusManagedIdentity.name
output serviceBusManagedIdentityObjectId string = serviceBusManagedIdentity.properties.principalId

output serviceBusKeyVaultReaderAccessId string = serviceBusKeyVaultReaderAccess.id
output serviceBusKeyVaultEncryptionUserAccessId string = serviceBusKeyVaultEncryptionUser.id
