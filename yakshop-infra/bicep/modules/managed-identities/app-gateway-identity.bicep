param location string
param environment string
param systemCode string

var preExistingMicrosoftRoles = {
  KeyVaultReader: '21090545-7ca7-4776-b22c-e363652d74d2'
  KeyVaultSecretsUser: '4633458b-17de-408a-b874-0445c86b69e6'
  KeyVaultCertificatesOfficer: 'a4417e6f-fecd-4de8-b567-7b0420556985'
}

resource keyVaultReadAccessRole 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  name: preExistingMicrosoftRoles.KeyVaultReader
}

resource keyVaultSecretsUserRole 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  name: preExistingMicrosoftRoles.KeyVaultSecretsUser
}

resource keyVaultCertificatesOfficerRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  name: preExistingMicrosoftRoles.KeyVaultCertificatesOfficer
}

var appGatewayManagedIdentityName = '${systemCode}-${environment}-app-gateway-managed-identity'

resource appGatewayManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: appGatewayManagedIdentityName
  location: location
}

resource appGatewayKeyVaultCertificatesOfficerRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('${appGatewayManagedIdentityName}-certificate-keyvault-officer')
  properties: {
    roleDefinitionId: keyVaultCertificatesOfficerRole.id
    principalId: appGatewayManagedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource appGatewayKeyVaultReadAccess 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid('${appGatewayManagedIdentityName}-keyvault-access')
  properties: {
    roleDefinitionId: keyVaultReadAccessRole.id
    principalId: appGatewayManagedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource appGatewayKeyVaultSecretsUser 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid('${appGatewayManagedIdentityName}-keyvault-secrets-user')
  properties: {
    roleDefinitionId: keyVaultSecretsUserRole.id
    principalId: appGatewayManagedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

output appGatewayManagedIdentityName string = appGatewayManagedIdentity.name
output appGatewayManagedIdentityObjectId string = appGatewayManagedIdentity.properties.principalId

output appGatewayKeyVaultSecretsUserAssignmentId string = appGatewayKeyVaultSecretsUser.id
output appGatewayKeyVaultCertificateOfficerAssignmentId string = appGatewayKeyVaultCertificatesOfficerRole.id
