// =============================================================
// DK WAVE TECHNOLOGY — Azure Administrator Hands-On Lab
// Template Bicep VM — Machine virtuelle Ubuntu
// Phase 5 — Automatisation & Optimisation
// Note : déploiement bloqué par quota vCPUs (4/4 utilisés)
// Template validé syntaxiquement par Azure
// =============================================================

@description('Nom de la VM')
param vmName string = 'vm-app-bicep'

@description('Région Azure')
param location string = 'westeurope'

@description('Taille de la VM')
param vmSize string = 'Standard_B1s'

@description('Nom d\'utilisateur administrateur')
param adminUsername string = 'azureadmin'

@description('Mot de passe administrateur')
@secure()
param adminPassword string

@description('ID du sous-réseau cible')
param subnetId string

@description('Environnement')
param environment string = 'Prod'

var nicName = '${vmName}-nic'
var osDiskName = '${vmName}-osdisk'

resource networkInterface 'Microsoft.Network/networkInterfaces@2023-04-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetId
          }
          privateIPAllocationMethod: 'Dynamic'
          // Aucune IP publique — accès via Bastion uniquement
        }
      }
    ]
  }
  tags: {
    Environment: environment
    Company: 'DK-WAVE'
    Owner: 'IT'
    CostCenter: 'IT-OPS'
  }
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: vmName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      linuxConfiguration: {
        disablePasswordAuthentication: false
        patchSettings: {
          patchMode: 'AutomaticByPlatform'
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        name: osDiskName
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
        }
      ]
    }
  }
  tags: {
    Environment: environment
    Company: 'DK-WAVE'
    Owner: 'IT'
    CostCenter: 'IT-OPS'
  }
}

output vmId string = virtualMachine.id
output vmPrivateIp string = networkInterface.properties.ipConfigurations[0].properties.privateIPAddress
