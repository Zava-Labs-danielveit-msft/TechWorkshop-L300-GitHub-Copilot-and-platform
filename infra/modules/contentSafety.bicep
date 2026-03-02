@description('Content Safety account name (globally unique).')
param name string

@description('Azure region for the Content Safety account.')
param location string

@description('SKU for the Content Safety account (e.g. S0).')
param skuName string = 'S0'

resource contentSafety 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: name
  location: location
  kind: 'ContentSafety'
  sku: {
    name: skuName
  }
  properties: {
    customSubDomainName: name
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: true
  }
}

output id string = contentSafety.id
output name string = contentSafety.name
output endpoint string = contentSafety.properties.endpoint
