param storageAccountName string 
param location string
param storageAccountType string

param blobServiceName string
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'StorageV2'
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2021-06-01' = {
  name: blobServiceName
  parent: storageAccount
}

output storageAccountId string = storageAccount.id
output storageUri string = storageAccount.properties.primaryEndpoints.blob

