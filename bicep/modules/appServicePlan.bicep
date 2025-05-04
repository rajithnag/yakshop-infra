param location string
param environment string
param kind string = 'elastic' // Selecting 'elastic' for Elastic Premium so that automatic scaling is enabled
param skuName string = 'EP1' 
param tier string = 'ElasticPremium'
param skuSize string = 'EP1'
param skuFamily string = 'EP'
var isProd = (environment == 'prd') 


resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  location: location
  name: 'yakshop-app-service-plan-${environment}'
  kind: kind
  sku: {
    name: skuName
    tier: tier
    size: skuSize
    family: skuFamily
    capacity: isProd ? 3 : 1 // Set minimum 3 number of always-on instances for production and 1 for non-production
  }
  properties: {
    reserved: true
    elasticScaleEnabled: true // Enable auto scaling
    maximumElasticWorkerCount: 100 
    perSiteScaling: false // not supported on Elastic Premium plans
  }
}

resource appServicePlanAutoscale 'Microsoft.Insights/autoscalesettings@2015-04-01' = {
  name: 'yakshop-appservice-autoscale-${environment}'
  location: location
  properties: {
    profiles: [
      {
        name: 'Default'
        capacity: {
          minimum: isProd ? '3' : '1'
          maximum: '50' // Maximum number of instances automatically scaled out to incase of high load like Black Friday
          default: isProd ? '3' : '1'
        }
        rules: [
          // Rules for scaling out and scaling in based on CPU percentage
          {
            // Scale out when CPU > 80% for 5 minutes.
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricResourceUri: appServicePlan.id
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'GreaterThan'
              threshold: 80
              dimensions: []
            }
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M' // 5 minutes cooldown for scale-out
            }
          }
          {
            // Scale in when CPU < 30% for 5 minutes. This is a conservative approach to avoid scaling in too quickly.
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricResourceUri: appServicePlan.id
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'LessThan'
              threshold: 30
              dimensions: []
            }
            scaleAction: {
              direction: 'Decrease'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M' // 5 minutes cooldown for scale-in
            }
          }
        ]
      }
    ]
    enabled: true
    targetResourceUri: appServicePlan.id
  }
}

output appServicePlanName string = appServicePlan.name
output appServicePlanId string = appServicePlan.id
