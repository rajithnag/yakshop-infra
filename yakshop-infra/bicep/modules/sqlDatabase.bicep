param environment string
param location string

var serverName = 'yakshop-sql-${environment}'
var databaseName = 'yakshopdb-${environment}'

param keyVaultName string
param sqlAdminSecretName string = 'sql-admin-password'
param databaseSubnetId string 
param appSubnetId string    
param sqlDbManagedIdentityName string


resource sqlDbManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: sqlDbManagedIdentityName
}

resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' existing = {
  name: keyVaultName
}
resource sqlAdminSecret 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' existing = {
  name: sqlAdminSecretName
  parent: keyVault
}

var sqlAdminPassword = sqlAdminSecret.properties.value


resource sqlServerResource 'Microsoft.Sql/servers@2021-02-01-preview' = {
  name: serverName
  location: location
  properties: {
    administratorLogin: 'sqladminuser'
    administratorLoginPassword: sqlAdminPassword
  }
}

// Create a private endpoint for the SQL server in the database subnet
resource sqlPrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: 'yakshop-sql-pe-${environment}'
  location: location
  properties: {
    subnet: {
      id: databaseSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'yakshop-sql-pls-${environment}'
        properties: {
          privateLinkServiceId: sqlServerResource.id
          groupIds: [
            'sqlServer'
          ]
        }
      }
    ]
  }
}

// Create a Private DNS Zone for Azure SQL
resource sqlPrivateDnsZone 'Microsoft.Network/privateDnsZones@2018-09-01' existing = {
  name: 'privatelink.${az.environment().suffixes.sqlServerHostname}'
}

// Link it to the VNet to enable DNS resolution of the SQL Private Endpoint within the VNet
resource sqlDnsZoneVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  name: 'yakshop-sql-dnslink-${environment}'
  parent: sqlPrivateDnsZone
  location: 'global'
  properties: {
    virtualNetwork: {
      id: split(databaseSubnetId, '/subnets/')[0]
    }
    registrationEnabled: false
  }
}

// Allow Azure SQL to accept traffic only from app subnet
resource sqlVnetRule 'Microsoft.Sql/servers/virtualNetworkRules@2022-02-01-preview' = {
  name: 'yakshop-sql-vnet-rule'
  parent: sqlServerResource
  properties: {
    virtualNetworkSubnetId: appSubnetId
    ignoreMissingVnetServiceEndpoint: false
  }
}

resource sqlDatabase 'Microsoft.Sql/servers/databases@2021-02-01-preview' = {
  name: databaseName
  parent: sqlServerResource
  location: location
  sku: {
    name: 'GP_Gen5_8' // General Purpose Gen5 with 8 vCores. I am not selecting serverless since it might have cold start issues and black friday kind of traffic might not be suitable for serverless.
    tier: 'GeneralPurpose'
    capacity: 8 // Number of vCores. I have set this to maximum number but we can change it lower number.
  }
  properties: {
    maxSizeBytes: 107374182400 // 100 GB
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    zoneRedundant: true
  }
}

// encrypt the data at rest using TDE
resource tde 'Microsoft.Sql/servers/databases/transparentDataEncryption@2021-02-01-preview' = {
  name: 'current'
  parent: sqlDatabase
  properties: {
    state: 'Enabled'
  }
}

resource threatDetection 'Microsoft.Sql/servers/databases/securityAlertPolicies@2021-02-01-preview' = {
  name: 'Default'
  parent: sqlDatabase
  properties: {
    state: 'Enabled'
    emailAccountAdmins: true
    disabledAlerts: []
    emailAddresses: [
      'admin@yakshop.com'
    ]
    retentionDays: 90
  }
}

resource sqlAadAdmin 'Microsoft.Sql/servers/administrators@2022-02-01-preview' = {
  name: 'ActiveDirectory'
  parent: sqlServerResource
  properties: {
    administratorType: 'ActiveDirectory'
    login: sqlDbManagedIdentity.name
    sid: sqlDbManagedIdentity.properties.principalId
    tenantId: subscription().tenantId
  }
}


// -- Need to run this script in the SQL Server to create the user for the managed identity and assign roles after the deployment§
// CREATE USER 'yak-${environment}-sql-db-user-managed-identity' FROM EXTERNAL PROVIDER;
// ALTER ROLE db_datareader ADD MEMBER 'yak-${environment}-sql-db-user-managed-identity';
// ALTER ROLE db_datawriter ADD MEMBER 'yak-${environment}-sql-db-user-managed-identity';
// -- Add more roles as needed
