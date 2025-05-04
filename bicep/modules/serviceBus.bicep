param environment string
param location string
param encryptionKeyName string
param keyvaultUri string
param serviceBusManagedIdentityName string


resource encryptionKey 'Microsoft.KeyVault/vaults/keys@2023-02-01' existing = {
  name: encryptionKeyName
}

resource serviceBusManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: serviceBusManagedIdentityName
}

resource serviceBus 'Microsoft.ServiceBus/namespaces@2023-01-01-preview' = {
  name: 'yakshop-servicebus-${environment}'
  location: location
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
  properties: {
    zoneRedundant: false
    encryption: {
      keySource: 'Microsoft.KeyVault'
      keyVaultProperties: [
        {
          identity: {
            userAssignedIdentity: serviceBusManagedIdentity.id
          }
          keyName: encryptionKey.name
          keyVaultUri: keyvaultUri
        }
      ]
      requireInfrastructureEncryption: true
    }

  }
}


resource serviceBusQueue 'Microsoft.ServiceBus/namespaces/queues@2023-01-01-preview' = {
  name: 'yakshop-servicebus-queue-${environment}'
  parent: serviceBus
  properties: {
    maxSizeInMegabytes: 1024
    requiresDuplicateDetection: false
    defaultMessageTimeToLive: 'PT5D'
    deadLetteringOnMessageExpiration: true
    lockDuration: 'PT30S'
    maxDeliveryCount: 5 // Maximum number of times a message can be delivered before being sent to the dead-letter queue
  }
}

output serviceBusNamespaceId string = serviceBus.id
output serviceBusQueueId string = serviceBusQueue.id
output serviceBusNamespaceName string = serviceBus.name
output serviceBusQueueName string = serviceBusQueue.name
