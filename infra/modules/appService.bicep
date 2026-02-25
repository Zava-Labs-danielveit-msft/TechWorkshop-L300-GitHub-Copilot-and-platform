@description('Web App name (must be globally unique).')
param name string

@description('Azure region for the App Service resources.')
param location string

@description('App Service plan name.')
param planName string

@description('App Service plan SKU (Linux).')
param planSku string

@description('Full container image name including registry (loginServer/repo:tag).')
param imageName string

@description('ACR login server name (e.g. myacr.azurecr.io).')
param acrLoginServer string

@description('Container port exposed by the app.')
param appPort string

@description('Application Insights connection string.')
param appInsightsConnectionString string

@description('Application Insights instrumentation key.')
param appInsightsInstrumentationKey string

@description('Azure AI Foundry endpoint for the app to call.')
param aiEndpoint string

@description('Phi deployment name to use for chat requests.')
param phiDeploymentName string

resource plan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: planName
  location: location
  sku: {
    name: planSku
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

resource webApp 'Microsoft.Web/sites@2023-01-01' = {
  name: name
  location: location
  kind: 'app,linux,container'
  tags: {
    'azd-service-name': 'web'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: plan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOCKER|${imageName}'
      acrUseManagedIdentityCreds: true
      appSettings: [
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${acrLoginServer}'
        }
        {
          name: 'WEBSITES_PORT'
          value: appPort
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsInstrumentationKey
        }
        {
          name: 'Foundry__Endpoint'
          value: aiEndpoint
        }
        {
          name: 'Foundry__PhiDeployment'
          value: phiDeploymentName
        }
      ]
    }
  }
}

output name string = webApp.name
output principalId string = webApp.identity.principalId
