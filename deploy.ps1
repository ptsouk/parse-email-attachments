$tenantId = "a6e09f1d-1f05-497b-b499-da099ced752f"
$subscriptionId = "8194f7dc-68ee-4dff-a67e-b01eec9ed54d"

#connect
Connect-AzAccount -TenantId $tenantId -subscription $subscriptionId

New-AzSubscriptionDeployment `
-locationFromTemplate 'westeurope' `
-location 'westeurope' `
-subscriptionId $subscriptionId `
-TemplateFile './main.bicep' `
-TemplateParameterFile './parameters/main.parameters.json' `
-DeploymentDebugLogLevel 'All' `
-Verbose