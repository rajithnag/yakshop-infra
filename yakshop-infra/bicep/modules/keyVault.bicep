param environment string
param location string
param skuName string = 'standard'
param tenantId string = subscription().tenantId

var keyVaultName = '${environment}-keyvault'


resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: skuName
    }
    tenantId: tenantId
    accessPolicies: []
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: true
  }
}

resource serviceBusEncryptionKey 'Microsoft.KeyVault/vaults/keys@2023-02-01' = {
  name: 'serviceBusEncryptionKey'
  parent: keyVault
  properties: {
    attributes: {
      enabled: true
      exp: dateTimeToEpoch('05/04/2026 11:00:00 AM')
      exportable: false
    }
    keySize: 4096
    kty: 'RSA'
  }
}

resource storageAccountEncryptionKey 'Microsoft.KeyVault/vaults/keys@2023-02-01' = {
  name: 'storageAccountEncryptionKey'
  parent: keyVault
  properties: {
    attributes: {
      enabled: true
      exp: dateTimeToEpoch('05/04/2026 11:00:00 AM')
      exportable: false
    }
    keySize: 4096
    kty: 'RSA'
  }
}

resource sqlDbEncryptionKey 'Microsoft.KeyVault/vaults/keys@2022-07-01' = {
  name: 'sqlDbEncryptionKey'
  parent: keyVault
  properties: {
    attributes: {
      enabled: true
      exp: dateTimeToEpoch('05/04/2026 11:00:00 AM')
      exportable: false
    }
    keySize: 2048
    kty: 'RSA'
  }
}

output keyVaultUri string = keyVault.properties.vaultUri
output keyVaultName string = keyVault.name
output serviceBusEncryptionKeyName string = serviceBusEncryptionKey.name
output storageAccountEncryptionKeyName string = storageAccountEncryptionKey.name
output sqlDbEncryptionKeyName string = sqlDbEncryptionKey.name
