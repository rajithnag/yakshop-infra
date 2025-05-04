param environment string
param location string
param encryptionKeyName string
param keyvaultUri string
param storageAccountManagedIdentityName string

resource storageAccountManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: storageAccountManagedIdentityName
}

var encryption = {
  requireInfrastructureEncryption: true
  keySource: 'Microsoft.Keyvault'
  services: {
    blob: {
      keyType: 'Account'
      enabled: true
    }
    file: {
      keyType: 'Account'
      enabled: true
    }
    queue: {
      keyType: 'Account'
      enabled: true
    }
    table: {
      keyType: 'Account'
      enabled: true
    }
  }
  keyvaultproperties:{
    keyname: encryptionKeyName
    keyvaulturi: keyvaultUri
  }
  identity: {
    userAssignedIdentity: storageAccountManagedIdentity.id
    }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: '${environment}yakshopstorage'
  location: location
  sku: {
    name: 'Standard_LRS' // Keeping it to Standard locally redundant storage since data in the storage account is not critical and its cost-effective
  }
  kind: 'StorageV2' // Keeping it to general purpose so that it can be used for various purposes.
  properties: {
    supportsHttpsTrafficOnly: true
    encryption: encryption
  }
}

// Add a blob container for website images and assets
resource webAssetsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-04-01' = {
  name: '${storageAccount.name}/default/website-images'
  properties: {
    publicAccess: 'Blob' // This allows public read access to the container
  }
}

// For logs and other data that should not be publicly accessible.
resource logsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-04-01' = {
  name: '${storageAccount.name}/default/logs'
  properties: {
    publicAccess: 'None'
  }
}

// For database or configuration backups.
resource backupsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-04-01' = {
  name: '${storageAccount.name}/default/backups'
  properties: {
    publicAccess: 'None'
  }
}

output storageAccountName string = storageAccount.name
output webAssetsContainerName string = webAssetsContainer.name
output logsContainerName string = logsContainer.name
output backupsContainerName string = backupsContainer.name
