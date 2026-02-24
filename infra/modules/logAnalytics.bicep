@description('Log Analytics workspace name.')
param name string

@description('Azure region for the workspace.')
param location string

@description('Retention in days for logs.')
param retentionInDays int = 30

resource workspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: name
  location: location
  properties: {
    retentionInDays: retentionInDays
  }
}

output id string = workspace.id
output name string = workspace.name
