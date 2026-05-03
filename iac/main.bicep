// =============================================================
// DK WAVE TECHNOLOGY — Azure Administrator Hands-On Lab
// Template Bicep principal — Compte de stockage
// Phase 5 — Automatisation & Optimisation
// =============================================================

@description('Région Azure de déploiement')
param location string = 'westeurope'

@description('Environnement cible')
@allowed(['Prod', 'NonProd'])
param environment string = 'Prod'

@description('Nom du projet')
param projectName string = 'dkwave'

// Nom unique généré automatiquement (évite les conflits globaux)
var storageAccountName = 'st${projectName}${uniqueString(resourceGroup().id)}'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
  }
  tags: {
    Environment: environment
    Company: 'DK-WAVE'
    Owner: 'IT'
    CostCenter: 'IT-OPS'
  }
}

output storageAccountName string = storageAccount.name
output storageAccountId string = storageAccount.id
