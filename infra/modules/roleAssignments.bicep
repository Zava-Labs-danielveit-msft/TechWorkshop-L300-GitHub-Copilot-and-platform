@description('Resource ID of the Azure Container Registry.')
param acrId string

@description('Principal ID of the Web App managed identity.')
param principalId string

@description('Resource ID of the Microsoft Foundry (Cognitive Services) account.')
param foundryId string

@description('Resource ID of the Content Safety account.')
param contentSafetyId string

var acrPullRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
var cognitiveServicesUserRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'a97b65f3-24c7-4388-baec-2e87135dc908')

var acrName = last(split(acrId, '/'))
var foundryName = last(split(foundryId, '/'))
var contentSafetyName = last(split(contentSafetyId, '/'))

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: acrName
}

resource foundry 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: foundryName
}

resource contentSafety 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: contentSafetyName
}

resource acrPull 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, principalId, 'acrpull')
  scope: acr
  properties: {
    roleDefinitionId: acrPullRoleDefinitionId
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}

resource cognitiveServicesUser 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(foundry.id, principalId, 'cogsvcuser')
  scope: foundry
  properties: {
    roleDefinitionId: cognitiveServicesUserRoleDefinitionId
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}

resource contentSafetyUser 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(contentSafety.id, principalId, 'contentsafetyuser')
  scope: contentSafety
  properties: {
    roleDefinitionId: cognitiveServicesUserRoleDefinitionId
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}
