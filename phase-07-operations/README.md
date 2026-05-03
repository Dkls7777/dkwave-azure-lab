# Phase 7 — Daily Administration & Operations
**DK WAVE TECHNOLOGY · Azure Administrator Hands-On Lab**

> **Statut** : ✅ Complétée · **Inventaire final** : 39 ressources · 5 resource groups

---

## Objectif

Pratiquer les responsabilités récurrentes d'un administrateur Azure en conditions réelles.

> *Un bon administrateur ne crée pas des incidents. Il les évite.*

---

## 7.1 — Cycle de vie utilisateurs (Joiner / Mover / Leaver)

### JOINER — Nouveau collaborateur

```bash
az ad user create \
  --display-name "Charlie Dev" \
  --user-principal-name charlie.dev@<TENANT_DOMAIN> \
  --password "<REDACTED>" \
  --force-change-password-next-sign-in true

az ad group member add \
  --group GRP-AZ-Ops \
  --member-id <CHARLIE_OBJECT_ID>
```

### MOVER — Changement de rôle

```bash
# Retirer de l'ancien groupe → éviter le privilege creep
az ad group member remove \
  --group GRP-DEV \
  --member-id <CHARLIE_OBJECT_ID>
```

### LEAVER — Départ (ordre critique : Bloquer → Révoquer → Retirer)

```bash
# 1. Bloquer immédiatement
az ad user update --id <CHARLIE_OBJECT_ID> --account-enabled false

# 2. Retirer de tous les groupes
az ad group member remove --group GRP-AZ-Ops --member-id <CHARLIE_OBJECT_ID>
```

---

## 7.2 — Comptes de service

```bash
# Audit des rôles RBAC
az role assignment list \
  --assignee svc-backup@<TENANT_DOMAIN> \
  --query "[].{Role:roleDefinitionName, Scope:scope}" -o table

# Désactiver le login interactif
az ad user update \
  --id svc-backup@<TENANT_DOMAIN> \
  --account-enabled false
```

---

## 7.3 — Routine quotidienne

```bash
# Vérifier les alertes actives
az monitor metrics alert list \
  --resource-group rg-dkwave-prod \
  --query "[].{Nom:name, Severite:severity, Actif:enabled}" -o table

# Vérifier l'état des VMs
az vm list --resource-group rg-dkwave-prod \
  --query "[].{Nom:name, Etat:powerState}" -o table

# Inventaire des ressources
az resource list --query "[].{Nom:name, Type:type, RG:resourceGroup}" -o table | wc -l
```

---

## 7.4 — Incident Response (processus 5 étapes)

**Scénario** : CPU > 90 % détecté sur `vm-app01`

| Étape | Action |
|---|---|
| **1 — Accuser réception** | VM démarrée, investigation lancée |
| **2 — Vérifier métriques** | `az monitor metrics list` → CPU mesuré à 6.18 % |
| **3 — Analyser logs** | Requête KQL `Syslog` dans Log Analytics |
| **4 — Appliquer correctif** | Resize simulé (quota insuffisant — documenté) |
| **5 — Documenter** | Rapport incident archivé |

```bash
# Métriques CPU en temps réel
az monitor metrics list \
  --resource /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/rg-dkwave-prod/providers/Microsoft.Compute/virtualMachines/vm-app01 \
  --metric "Percentage CPU" \
  --interval PT1M \
  --output table
```

```kql
// Requête KQL - Analyse des logs système
Syslog
| where TimeGenerated > ago(30m)
| where Computer contains "vm-app01"
| project TimeGenerated, Computer, SeverityLevel, SyslogMessage
| take 10
```

---

## 7.5 — Change Management

**Changement** : Resize `vm-app01` → `Standard_D2als_v6`

```bash
# Vérifier les tailles disponibles
az vm list-vm-resize-options \
  --resource-group rg-dkwave-prod \
  --name vm-app01 --output table

# Appliquer le resize
az vm resize \
  --resource-group rg-dkwave-prod \
  --name vm-app01 \
  --size Standard_D2als_v6
```

Processus appliqué : **Planifier → Informer → Vérifier backup → Appliquer → Tester → Surveiller**

---

## 7.6 — Access Reviews

```bash
az role assignment list \
  --role Owner \
  --query "[].{Assignee:principalName, Scope:scope}" -o table

az role assignment list \
  --role Contributor \
  --query "[].{Assignee:principalName, Scope:scope}" -o table
```

**Résultat** : aucun privilege creep détecté ✅

---

## 7.7 — Rotation des secrets Key Vault

```bash
# Nouvelle version du secret (valeur non exposée)
az keyvault secret set \
  --vault-name kv-dkwave-secure \
  --name DbPassword \
  --value "<REDACTED>"
```

> La rotation des secrets est une pratique mensuelle obligatoire en production.

---

## 7.8 — Inventaire final

| Resource Group | Ressources clés |
|---|---|
| `rg-dkwave-prod` | vm-app01, vm-web02, kv-dkwave-secure, lb-dkwave-web, Storage, Alertes |
| `rg-dkwave-shared` | VNet, NSGs, Bastion, azfw-dkwave, law-dkwave-prod, rsv-dkwave-prod |
| `rg-dkwave-nonprod` | Storage account non-prod |
| `NetworkWatcherRG` | Network Watcher West Europe |
| `AzureBackupRG` | Restore Points vm-app01 |

**Total : 39 ressources · 5 resource groups**

---

## Checklist finale

| Critère | Statut |
|---|---|
| Joiner/Mover/Leaver exécutés | ✅ |
| Comptes de service sécurisés | ✅ |
| Routine quotidienne documentée | ✅ |
| Incident traité en 5 étapes | ✅ |
| Resize appliqué avec processus complet | ✅ |
| Access Reviews : aucun privilege creep | ✅ |
| Secret DbPassword rotaté | ✅ |
| Inventaire 39 ressources produit | ✅ |
