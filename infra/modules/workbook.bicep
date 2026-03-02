@description('Workbook name (display name).')
param name string

@description('Azure region for the workbook.')
param location string

@description('Log Analytics workspace resource ID.')
param logAnalyticsWorkspaceId string

@description('Workbook definition JSON content.')
param workbookJson string

resource workbook 'Microsoft.Insights/workbooks@2023-06-01' = {
  name: guid(resourceGroup().id, name)
  location: location
  kind: 'shared'
  properties: {
    displayName: name
    sourceId: logAnalyticsWorkspaceId
    category: 'workbook'
    serializedData: workbookJson
  }
}

output id string = workbook.id
output name string = workbook.name
