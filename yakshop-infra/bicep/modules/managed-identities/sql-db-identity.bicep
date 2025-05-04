param location string
param environment string
param systemCode string

// Pre existing roles created by Microsoft.
// https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
var preExistingMicrosoftRoles = {
  KeyVaultCryptoServiceEncryptionUser: 'e147488a-f6f5-4113-8e2d-b22465e65bf6'
  KeyVaultReader: '21090545-7ca7-4776-b22c-e363652d74d2'
}

resource keyVaultCryptoServiceEncryptionUserRole 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  name: preExistingMicrosoftRoles.KeyVaultCryptoServiceEncryptionUser
}

resource keyVaultReadAccessRole 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  name: preExistingMicrosoftRoles.KeyVaultReader
}

var sqlDbManagedIdentityName = '${systemCode}-${environment}-sql-db-user-managed-identity'

resource sqlDBManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: sqlDbManagedIdentityName
  location: location
}

resource sqlDbKeyVaultAccess 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid('${sqlDbManagedIdentityName}-keyvault-access')
  properties: {
    roleDefinitionId: keyVaultCryptoServiceEncryptionUserRole.id
    principalId: sqlDBManagedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource yakSqlDbKeyVaultReadAccess 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid('${sqlDbManagedIdentityName}-keyvault-read-access')
  properties: {
    roleDefinitionId: keyVaultReadAccessRole.id
    principalId: sqlDBManagedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

output yakSqlDbIdentityName string = sqlDBManagedIdentity.name
output yakSqlDbIdentityObjectId string = sqlDBManagedIdentity.properties.principalId
