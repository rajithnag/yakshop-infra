param environment string
param location string


resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-10-01' = {
  name: 'yakshop-app-insights-workspace-${environment}'
  location: location
  properties: {
    sku: {
      name: 'LACluster'
    }
    retentionInDays: 90
    features: {
      searchVersion: 1
      legacy: 0
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

resource appInsights 'microsoft.insights/components@2020-02-02' = {
  name: 'yakshop-app-insights-${environment}'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Bluefield'
    Request_Source: 'rest'
    RetentionInDays: 30 // Adjust as needed to save costs
    WorkspaceResourceId: logAnalyticsWorkspace.id // Link to Log Analytics workspace for advanced analytics and integration
  }
}

output appInsightsName string = appInsights.name
output appInsightsInstrumentationKey string = appInsights.properties.InstrumentationKey
output appInsightsConnectionString string = appInsights.properties.ConnectionString
