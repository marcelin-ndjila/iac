param location string = resourceGroup().location
param storageAccountName string = 'xceedst${uniqueString(resourceGroup().id)}'
param appServiceAppName string = 'xceedapp${uniqueString(resourceGroup().id)}'

@allowed([
  'nonprod'
  'prod'
])
param environmentType string


var storageAccountSkuName = (environmentType == 'prod') ? 'Standard_GRS' : 'Standard_LRS'


resource storageaccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageAccountSkuName
  }
  kind: 'StorageV2'
  properties:  {
    accessTier:'Hot'
  }
}

module app 'appService.bicep' = {
  name: 'app'
  params: {
    appServiceAppName: appServiceAppName
    environmentType: environmentType
    location: location
  }
}

output appServiceAppHostName string = app.outputs.appServiceAppHostName
