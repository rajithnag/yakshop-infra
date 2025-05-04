param environment string
param backendServices array

resource alertActionGroup 'Microsoft.Insights/actionGroups@2019-06-01' = {
  name: 'yakshop-alert-action-group-${environment}'
  location: 'global'
  properties: {
    groupShortName: 'yakshop'
    enabled: true
    emailReceivers: [
      {
        name: 'YakshopOps'
        emailAddress: 'admin@yakshop.com'
        useCommonAlertSchema: true
      }
    ]
  }
}

resource cpuAlertRules 'Microsoft.Insights/metricAlerts@2018-03-01' = [for app in backendServices: {
  name: '${app}-cpu-alert'
  location: 'global'
  properties: {
    description: 'CPU usage over 80% for 5 minutes'
    severity: 2
    enabled: true
    scopes: [
      resourceId('Microsoft.Web/sites', app)
    ]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'HighCPU'
          metricName: 'CpuPercentage'
          metricNamespace: 'Microsoft.Web/sites'
          operator: 'GreaterThan'
          threshold: 80
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    autoMitigate: true
    actions: [
      {
        actionGroupId: alertActionGroup.id
      }
    ]
  }
}]

resource http5xxAlertRules 'Microsoft.Insights/metricAlerts@2018-03-01' = [for app in backendServices: {
  name: '${app}-5xx-alert'
  location: 'global'
  properties: {
    description: 'HTTP 5xx errors detected'
    severity: 2
    enabled: true
    scopes: [
      resourceId('Microsoft.Web/sites', app)
    ]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'Http5xxErrors'
          metricName: 'Http5xx'
          metricNamespace: 'Microsoft.Web/sites'
          operator: 'GreaterThan'
          threshold: 1
          timeAggregation: 'Total'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    autoMitigate: true
    actions: [
      {
        actionGroupId: alertActionGroup.id
      }
    ]
  }
}]
