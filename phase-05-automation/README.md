# Phase 5 — Automatisation & Optimisation
**DK WAVE TECHNOLOGY · Azure Administrator Hands-On Lab**

> **Statut** : ✅ Complétée avec adaptations

---

## Objectif

Transformer l'infrastructure manuelle en un environnement réplicable, automatisé et financièrement maîtrisé.

> *ClickOps = Erreurs. Sans code de référence, les environnements Prod et NonProd divergent. Sans versioning, impossible de savoir qui a fait quoi et quand.*

---

## Résumé des réalisations

| Étape | Réalisation | Statut |
|---|---|---|
| IaC Setup | Environnement Cloud Shell + dossier `dkwave-iac/` | ✅ Validée |
| Bicep Template | Compte de stockage déployé (Prod + NonProd) | ✅ Validée |
| Multi-environnements | `prod.parameters.json` + `nonprod.parameters.json` | ✅ Validée |
| VM IaC | Template `vm.bicep` complet et validé | ⚠️ Quota insuffisant |
| Update Manager | `patch-config-prod` · vm-app01 + vm-web02 attachées | ✅ Validée |
| Tags | Audit complet · 8 ressources sans tags corrigées | ✅ Validée |
| Budget | 150 USD/mois · alertes 80 % et 100 % | ✅ Validée |
| Right-sizing | CPU < 1 % · recommandation Standard_D1ads_v6 | ✅ Validée |

---

## Étapes réalisées

### 5.2 — Préparation IaC

```bash
# Vérification de la subscription active
az account show --output table

# Création du dossier de projet
mkdir dkwave-iac && cd dkwave-iac
```

### 5.3 — Premier template Bicep

```bicep
// main.bicep - Compte de stockage avec tags et nom unique
param location string = 'westeurope'
param environment string = 'Prod'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'stdkwave${uniqueString(resourceGroup().id)}'
  location: location
  sku: { name: 'Standard_LRS' }
  kind: 'StorageV2'
  tags: {
    Environment: environment
    Company: 'DK-WAVE'
    Owner: 'IT'
    CostCenter: 'IT-OPS'
  }
}
```

- 1er déploiement : 23 secondes (création)
- 2ème déploiement : 1.3 secondes (idempotence — ressource existante détectée)

> **Idempotence** : Bicep déploie uniquement ce qui a changé. Propriété fondamentale de l'IaC.

### 5.4 — Multi-environnements

```json
// prod.parameters.json
{
  "parameters": {
    "environment": { "value": "Prod" }
  }
}
```

Un seul template, deux fichiers de paramètres → cohérence garantie entre Prod et NonProd.

### 5.5 — Template VM (vm.bicep)

Template complet avec NIC, tags, Managed Identity et configuration réseau privée. Déploiement bloqué par quota vCPUs (4/4 utilisés).

> **En entreprise** : augmentation de quota via demande formelle au support Microsoft (délai 24-48h). Procédure documentée et non bloquante sur le plan technique.

### 5.6 — Azure Update Manager

```bash
# Configuration de maintenance
az maintenance configuration create \
  --resource-group rg-dkwave-shared \
  --resource-name patch-config-prod \
  --maintenance-scope InGuestPatch \
  --recur-every "1Month First Sunday" \
  --start-date-time "2026-05-01 22:00" \
  --duration "03:00" \
  --reboot-setting IfRequired
```

| Paramètre | Valeur |
|---|---|
| Fenêtre | 1er de chaque mois à 22h00 UTC |
| Durée | 3 heures |
| Classifications | Critical + Security (Windows + Linux) |
| Redémarrage | IfRequired |
| VMs couvertes | vm-app01 (Ubuntu) + vm-web02 (Windows) |

### 5.7 — Audit des tags

8 ressources sans tags détectées et corrigées :
- 2 NICs
- 2 disques OS
- IP publique Application Gateway
- Politique WAF
- + 2 autres ressources

### 5.8 — Cost Management & Budget

```bash
az consumption budget create \
  --budget-name dkwave-budget-prod-2026 \
  --amount 150 \
  --time-grain Monthly \
  --start-date 2026-01-01 \
  --end-date 2028-03-31
```

| Seuil | Montant | Action |
|---|---|---|
| 80 % | 120 USD | Notification email |
| 100 % | 150 USD | Notification email |

> Un budget ne coupe pas les ressources — il déclenche des alertes pour agir proactivement.

### 5.9 — Right-sizing

CPU moyen observé sur `vm-app01` : **< 1 %** (0.86 %, 0.49 %, 0.49 %)

Recommandation : downgrade vers `Standard_D1ads_v6` (1 vCPU) — réduction de coût de ~50 %.

---

## Difficultés rencontrées & enseignements

| Problème | Cause | Solution | Enseignement |
|---|---|---|---|
| Quota vCPUs épuisé | 4/4 cores utilisés par vm-app01 et vm-web02 | Template validé, déploiement différé | Gérer les quotas est une responsabilité du Cloud Admin |
| Extensions CLI preview instables | `Microsoft.Maintenance` non documenté | Basculement sur `az rest` + portail | Savoir quand la CLI est contre-productive |
| `bypassPlatformSafetyChecksOnUserSchedule` requis | Non documenté dans les messages d'erreur | Configuration via `az rest` | Lire les messages d'erreur Azure avec précision |
| Timeouts réseau lors des attachements | Azure asynchrone | Vérification état réel dans portail | Un timeout client ≠ un échec serveur |

---

## Enseignements clés

- **IaC = reproductibilité** : un template Bicep corrigé une fois l'est pour tous les déploiements futurs
- **Paramétrage multi-env** : un seul template, N environnements identiques
- **Pragmatisme** : CLI → API REST → portail selon les contraintes. Ce qui compte c'est le résultat
- **FinOps** : l'administrateur est co-responsable du budget cloud
