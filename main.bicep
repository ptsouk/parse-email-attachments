targetScope = 'subscription'

@description('Name for the resource group used for the resources deployment.')
param resourceGroupName string = 'parse-email-rg'

@description('Location for all resources.')
param location string = 'westeurope'

@description('The name of the Log Analytics Workspace.')
param logAnalyticsWorkspaceName string = 'parse-email-law'

@description('The name of the Application Insights.')
param applicationInsightsName string = 'parse-email-AppIns'

@description('The name of the App Service Plan.')
param funcAppServicePlanName string = 'parse-email-FuncPlan'

@description('The name of the App Service.')
param funcAppServiceName string = 'parse-email-Func'

@description('The language worker runtime to load in the function app.')
param runtime string = 'dotnet'

@description('Name for the storage account.')
param storageAccountName string = 'parseemailstracc'

param storageAccountType string = 'Standard_LRS'

@description('Name for the storage account.')
param blobServiceName string = 'default'

param workflowResourceName string = 'parse-email-la'

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: resourceGroupName
  location: location
}

module logAnalyticsWorkspace 'modules/logAnalyticsWorkspace_module.bicep' = {
  scope: resourceGroup(rg.name)
  name: '${logAnalyticsWorkspaceName}-${uniqueString(rg.id)}'
  params: {
    logAnalyticsWorkspaceName: '${logAnalyticsWorkspaceName}-${uniqueString(rg.id)}'
    location: location
  }
}

module applicationInsights 'modules/applicationInsights_module.bicep' = {
  scope: resourceGroup(rg.name)
  name: '${applicationInsightsName}-${uniqueString(rg.id)}'
  params: {
    applicationInsightsName: '${applicationInsightsName}-${uniqueString(rg.id)}'
    location: location
    logAnalyticsWorkspaceId: logAnalyticsWorkspace.outputs.logAnalyticsWorkspaceId
  }
}

module functionAppService 'modules/functionAppService_module.bicep' = {
  scope: resourceGroup(rg.name)
  name: '${funcAppServiceName}-${uniqueString(rg.id)}'
  params: {
    storageAccountName: toLower('${storageAccountName}${uniqueString(rg.id)}fa')
    location: location
    appServicePlanName: '${funcAppServicePlanName}-${uniqueString(rg.id)}'
    functionAppName: '${funcAppServiceName}-${uniqueString(rg.id)}'
    applicationInsightsName: applicationInsights.name
    runtime: runtime
  }
}

module storageAccount 'modules/storageAccount_module.bicep' = {
  scope: resourceGroup(rg.name)
  name: toLower('${storageAccountName}${uniqueString(rg.id)}')
  params: {
    storageAccountName: toLower('${storageAccountName}${uniqueString(rg.id)}')
    location: location
    blobServiceName: blobServiceName
    storageAccountType: storageAccountType
  }
}

module workflow 'modules/parse-email_workflowResource.bicep' = {
  scope: resourceGroup(rg.name)
  name: '${workflowResourceName}-${uniqueString(rg.id)}'
  params: {
    location: location
    workflowResourceName: '${workflowResourceName}-${uniqueString(rg.id)}'
    functionAppResourceID: functionAppService.outputs.functionAppResourceID
  }
}
