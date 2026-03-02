targetScope = 'resourceGroup'

@description('Azure region for all resources.')
param location string = 'westus3'

@description('Environment name (e.g. dev, test, prod).')
param environmentName string = 'dev'

@description('Short prefix for resource naming.')
param namePrefix string = 'zava'

@description('SKU for Azure Container Registry.')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param acrSku string = 'Basic'

@description('SKU for App Service Plan (Linux).')
param appServiceSku string = 'B1'

@description('Container image name (repository:tag) to deploy.')
param appImageName string = 'zavastorefront:dev'

@description('Container port exposed by the app.')
param appPort string = '8080'

@description('Azure AI (Foundry) account SKU.')
param aiSkuName string = 'S0'

@description('Azure AI Content Safety account SKU.')
param contentSafetySkuName string = 'S0'

@description('GPT-4 deployment name.')
param gpt4DeploymentName string = 'gpt-4'

@description('GPT-4 model name.')
param gpt4ModelName string = 'gpt-4'

@description('GPT-4 model version.')
param gpt4ModelVersion string = 'latest'

@description('GPT-4 deployment capacity.')
param gpt4Capacity int = 1

@description('Whether to deploy the GPT-4 model in Azure AI Foundry.')
param enableGpt4Deployment bool = true

@description('Phi deployment name.')
param phiDeploymentName string = 'phi-4'

@description('Phi model name.')
param phiModelName string = 'phi-4'

@description('Phi model version.')
param phiModelVersion string = 'latest'

@description('Phi deployment capacity.')
param phiCapacity int = 1

@description('Whether to deploy the Phi model in Azure AI Foundry.')
param enablePhiDeployment bool = true

var cleanPrefix = toLower(replace(namePrefix, '-', ''))
var suffix = toLower(uniqueString(resourceGroup().id, environmentName))

var acrName = '${cleanPrefix}acr${suffix}'
var logAnalyticsName = toLower('${namePrefix}-law-${environmentName}')
var appInsightsName = toLower('${namePrefix}-appi-${environmentName}')
var appServicePlanName = toLower('${namePrefix}-asp-${environmentName}')
var webAppName = toLower('${namePrefix}-web-${environmentName}-${suffix}')
var aiAccountName = '${cleanPrefix}ai${suffix}'
var contentSafetyName = '${cleanPrefix}cs${suffix}'

module acr 'modules/acr.bicep' = {
  name: 'acr'
  params: {
    name: acrName
    location: location
    sku: acrSku
  }
}

module logAnalytics 'modules/logAnalytics.bicep' = {
  name: 'log-analytics'
  params: {
    name: logAnalyticsName
    location: location
  }
}

module appInsights 'modules/appInsights.bicep' = {
  name: 'app-insights'
  params: {
    name: appInsightsName
    location: location
    workspaceResourceId: logAnalytics.outputs.id
  }
}

module appService 'modules/appService.bicep' = {
  name: 'app-service'
  params: {
    name: webAppName
    location: location
    planName: appServicePlanName
    planSku: appServiceSku
    imageName: '${acr.outputs.loginServer}/${appImageName}'
    acrLoginServer: acr.outputs.loginServer
    appPort: appPort
    appInsightsConnectionString: appInsights.outputs.connectionString
    appInsightsInstrumentationKey: appInsights.outputs.instrumentationKey
    aiEndpoint: foundry.outputs.endpoint
    phiDeploymentName: phiDeploymentName
    contentSafetyEndpoint: contentSafety.outputs.endpoint
  }
}

module roleAssignments 'modules/roleAssignments.bicep' = {
  name: 'role-assignments'
  params: {
    acrId: acr.outputs.id
    principalId: appService.outputs.principalId
    foundryId: foundry.outputs.id
    contentSafetyId: contentSafety.outputs.id
  }
}

module foundry 'modules/foundry.bicep' = {
  name: 'foundry'
  params: {
    name: aiAccountName
    location: location
    skuName: aiSkuName
    logAnalyticsWorkspaceId: logAnalytics.outputs.id
    gpt4DeploymentName: gpt4DeploymentName
    gpt4ModelName: gpt4ModelName
    gpt4ModelVersion: gpt4ModelVersion
    gpt4Capacity: gpt4Capacity
    enableGpt4Deployment: enableGpt4Deployment
    phiDeploymentName: phiDeploymentName
    phiModelName: phiModelName
    phiModelVersion: phiModelVersion
    phiCapacity: phiCapacity
    enablePhiDeployment: enablePhiDeployment
  }
}

module contentSafety 'modules/contentSafety.bicep' = {
  name: 'content-safety'
  params: {
    name: contentSafetyName
    location: location
    skuName: contentSafetySkuName
  }
}

output acrLoginServer string = acr.outputs.loginServer
output webAppName string = appService.outputs.name
output aiEndpoint string = foundry.outputs.endpoint
