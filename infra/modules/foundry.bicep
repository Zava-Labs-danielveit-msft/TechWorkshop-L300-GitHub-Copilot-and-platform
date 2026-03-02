@description('Azure AI Foundry account name (globally unique).')
param name string

@description('Azure region for the AI account.')
param location string

@description('SKU for the AI account (e.g. S0).')
param skuName string = 'S0'

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

@description('GPT-4 deployment name.')
param gpt4DeploymentName string

@description('GPT-4 model name.')
param gpt4ModelName string

@description('GPT-4 model version.')
param gpt4ModelVersion string

@description('GPT-4 deployment capacity.')
param gpt4Capacity int = 1

@description('Whether to deploy the GPT-4 model.')
param enableGpt4Deployment bool = true

@description('Phi deployment name.')
param phiDeploymentName string

@description('Phi model name.')
param phiModelName string

@description('Phi model version.')
param phiModelVersion string

@description('Phi deployment capacity.')
param phiCapacity int = 1

@description('Whether to deploy the Phi model.')
param enablePhiDeployment bool = true

resource aiAccount 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: name
  location: location
  kind: 'AIServices'
  sku: {
    name: skuName
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
  scope: aiAccount
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: diagnosticLogs
    metrics: diagnosticMetrics
  }
}

resource gpt4Deployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = if (enableGpt4Deployment) {
  name: gpt4DeploymentName
  parent: aiAccount
  sku: {
    name: 'Standard'
    capacity: gpt4Capacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: gpt4ModelName
      version: gpt4ModelVersion
    }
  }
}

resource phiDeployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = if (enablePhiDeployment) {
  name: phiDeploymentName
  parent: aiAccount
  sku: {
    name: 'Standard'
    capacity: phiCapacity
  }
  properties: {
    model: {
      format: 'microsoft'
      name: phiModelName
      version: phiModelVersion
    }
  }
}

output name string = aiAccount.name
output id string = aiAccount.id
output endpoint string = aiAccount.properties.endpoint
