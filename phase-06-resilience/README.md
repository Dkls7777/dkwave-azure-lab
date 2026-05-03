# Phase 6 — Résilience & Disaster Recovery
**DK WAVE TECHNOLOGY · Azure Administrator Hands-On Lab**

> **Statut** : ✅ Complétée · **Règle absolue** : Un backup non testé n'existe pas

---

## Objectif

Garantir que DK WAVE TECHNOLOGY peut survivre à tout incident majeur : suppression accidentelle, ransomware, erreur humaine, panne régionale.

---

## Ressources créées

| Ressource | Nom | Resource Group |
|---|---|---|
| Recovery Services Vault | `rsv-dkwave-prod` | rg-dkwave-shared |
| Backup Policy | `policy-vm-prod` | (dans le vault) |
| Resource Group de test | `rg-dkwave-restore-test` | (supprimé après validation) |

---

## Objectifs RTO/RPO définis

| Workload | RPO | RTO | Priorité | VM |
|---|---|---|---|---|
| Web VM | 24h | 4h | Moyenne | vm-web02 |
| App VM | 12h | 2h | **Haute** | vm-app01 |
| Données | 6h | 1h | **Critique** | Tous disques |
| NonProd | Best effort | Best effort | Faible | — |

> **RPO** = quantité maximale de données perdues acceptable (en durée)  
> **RTO** = temps maximum tolérable pour rétablir le service

---

## Étapes réalisées

### 6.2 — Recovery Services Vault

> Prérequis : enregistrement du namespace Microsoft.RecoveryServices

```bash
az provider register --namespace Microsoft.RecoveryServices --wait

# Création via az rest (Azure Policy bloque la commande standard)
az rest --method PUT \
  --uri ".../vaults/rsv-dkwave-prod?api-version=2023-04-01" \
  --body '{
    "location": "westeurope",
    "sku": { "name": "RS0", "tier": "Standard" },
    "properties": { "publicNetworkAccess": "Enabled" },
    "tags": {
      "Environment": "Production",
      "Owner": "IT-Admin",
      "Company": "DKWave",
      "CostCenter": "IT-OPS"
    }
  }'
```

**Résultat** : `provisioningState: Succeeded`

### 6.3 — Backup Policy

| Rétention | Fréquence | Durée |
|---|---|---|
| Daily | Backup à 23h00 UTC | **14 jours** |
| Weekly | Chaque dimanche | **4 semaines** |
| Monthly | Le 1er de chaque mois | **6 mois** |

### 6.4 — Protection des VMs

```bash
# vm-app01
az backup protection enable-for-vm \
  --resource-group rg-dkwave-shared \
  --vault-name rsv-dkwave-prod \
  --vm $(az vm show -g rg-dkwave-prod -n vm-app01 --query id -o tsv) \
  --policy-name policy-vm-prod

# vm-web02
az backup protection enable-for-vm \
  --resource-group rg-dkwave-shared \
  --vault-name rsv-dkwave-prod \
  --vm $(az vm show -g rg-dkwave-prod -n vm-web02 --query id -o tsv) \
  --policy-name policy-vm-prod
```

| VM | Policy | Statut |
|---|---|---|
| vm-app01 (Ubuntu) | policy-vm-prod | ✅ ConfigureBackup Completed |
| vm-web02 (Windows) | policy-vm-prod | ✅ ConfigureBackup Completed |

### 6.5 — Backup initial (manuel)

> Premier backup planifié à 23h00 — backup manuel déclenché immédiatement pour permettre le test.

**Exemption Azure Policy requise** pour `AzureBackupRG_westeurope_1` :

```bash
az policy exemption create \
  --name exempt-backup-rg-tags \
  --exemption-category Waiver \
  --policy-assignment ".../policyAssignments/require-tags" \
  --scope ".../resourceGroups/AzureBackupRG_westeurope_1"
```

| Phase | Durée | Statut |
|---|---|---|
| Take Snapshot | ~5 min | ✅ Completed |
| Transfer data to vault | ~10 min | ✅ Completed |
| Validate Backup | ~1 min | ✅ Completed |

### 6.6 — Test de restauration

> **Recovery Point utilisé** : 667849339843443 — 2026-04-27 09:45:33 UTC (CrashConsistent)

```bash
az backup restore restore-disks \
  --resource-group rg-dkwave-shared \
  --vault-name rsv-dkwave-prod \
  --container-name "IaasVMContainer;iaasvmcontainerv2;rg-dkwave-prod;vm-app01" \
  --item-name "VM;iaasvmcontainerv2;rg-dkwave-prod;vm-app01" \
  --rp-name "667849339843443" \
  --storage-account $(az storage account show \
    --name stdkwavecbg3cqgonj4p4 -g rg-dkwave-prod --query id -o tsv) \
  --target-resource-group rg-dkwave-restore-test
```

**Résultat** : `CompletedWithWarnings` — disques restaurés avec succès dans `rg-dkwave-restore-test`

> L'avertissement `RestoreTemplateNotValidated` est bénin dans le contexte lab — quota de redéploiement VM atteint, mais les disques sont intégralement restaurés.

Le RG de test a été supprimé après validation.

### 6.7 — Azure Site Recovery (ASR)

| Configuration prévue | Décision |
|---|---|
| Source : West Europe → Target : North Europe | ⏭️ Non activé — coûts de réplication continue hors scope budget lab |

---

## Checklist de validation finale

| Critère | Validation | Statut |
|---|---|---|
| Recovery Vault créé | rsv-dkwave-prod dans rg-dkwave-shared | ✅ |
| Policy configurée | 14j / 4 sem / 6 mois | ✅ |
| vm-app01 protégée | ConfigureBackup Completed | ✅ |
| vm-web02 protégée | ConfigureBackup Completed | ✅ |
| Backup initial réalisé | 3 phases Completed | ✅ |
| Restauration testée | CompletedWithWarnings — disques restaurés | ✅ |
| ASR configuré | Non activé (coût élevé) | ⏭️ |

---

## Règle fondamentale

> **Un backup non testé n'existe pas.**  
> Toujours valider la chaîne complète : backup → recovery point → restauration → validation.
