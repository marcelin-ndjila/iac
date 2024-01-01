az bicep build -f '01 Use modules.bicep'

Bicep build '01 Use modules.bicep'

New-AzResourceGroup -Name 'Bicep-Modules-01' -Location 'eastus' -Force
$Parameters = @{
    name                = "mainDeployment" + (Get-Date).ToString("yyyyMMddHHmmss")
    TemplateFile        = '01 Use Modules.bicep'
    ResourceGroupName   = 'Bicep-Modules-01'
    appServiceAppName   = 'bicepmoduleexample'
}

New-AzResourceGroupDeployment @Parameters -Verbose

https://4bes.nl/2021/10/10/get-a-consistent-azure-naming-convention-with-bicep-modules/