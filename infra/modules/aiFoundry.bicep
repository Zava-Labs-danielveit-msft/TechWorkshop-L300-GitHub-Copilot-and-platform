@description('Name of the Azure AI Foundry (AI Services) account')
param name string

@description('Azure region for the resource - must support GPT-4 and Phi models')
param location string

@description('Resource tags')
param tags object = {}

@description('Log Analytics workspace resource ID for diagnostics.')
param logAnalyticsWorkspaceId string

@description('Diagnostic log categories to enable for Microsoft Foundry.')
param diagnosticLogCategories array = [
  'Audit'
  'RequestResponse'
  'AzureOpenAIRequestUsage'
  'Trace'
]

@description('Diagnostic metric categories to enable for Microsoft Foundry.')
param diagnosticMetricCategories array = [
  'AllMetrics'
]

resource aiFoundry 'Microsoft.CognitiveServices/accounts@2024-04-01-preview' = {
  name: name
  location: location
  tags: tags
  kind: 'AIServices'
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: name
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: true
  }
}

var diagnosticLogs = [for category in diagnosticLogCategories: {
  category: category
  enabled: true
}]
var diagnosticMetrics = [for category in diagnosticMetricCategories: {
  category: category
  enabled: true
}]

resource aiDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${name}-diagnostics'
  scope: aiFoundry
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: diagnosticLogs
    metrics: diagnosticMetrics
  }
}

resource gpt4Deployment 'Microsoft.CognitiveServices/accounts/deployments@2024-04-01-preview' = {
  parent: aiFoundry
  name: 'gpt-4'
  sku: {
    name: 'Standard'
    capacity: 10
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4'
      version: '0613'
    }
  }
}

resource phiDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-04-01-preview' = {
  parent: aiFoundry
  name: 'phi-3-mini'
  dependsOn: [gpt4Deployment]
  sku: {
    name: 'Standard'
    capacity: 1
  }
  properties: {
    model: {
      format: 'Microsoft'
      name: 'Phi-3-mini-128k-instruct'
      version: '14'
    }
  }
}

output id string = aiFoundry.id
output name string = aiFoundry.name
output endpoint string = aiFoundry.properties.endpoint
