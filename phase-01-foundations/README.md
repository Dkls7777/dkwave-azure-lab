# Phase 1 — Mise en place des fondations
**DK WAVE TECHNOLOGY · Azure Administrator Hands-On Lab**

> **Statut** : ✅ Complétée · **Région** : West Europe

---

## Objectif

Construire une fondation Azure sécurisée avant tout déploiement.

> *Cette phase est axée sur le contrôle, la sécurité et la discipline — pas sur la vitesse. Les erreurs commises ici sont les plus coûteuses à corriger.*

---

## Ressources créées

| Ressource | Nom |
|---|---|
| Groupe de ressources | `rg-dkwave-shared` / `rg-dkwave-prod` / `rg-dkwave-nonprod` |
| Utilisateurs | `alice.admin` · `bob.ops` · `svc-backup` |
| Groupes | `GRP-AZ-Admins` · `GRP-AZ-Ops` · `GRP-AZ-Backup` |

---

## Commandes CLI exécutées

### Groupes de ressources

```bash
az group create --name rg-dkwave-shared --location westeurope
az group create --name rg-dkwave-prod --location westeurope
az group create --name rg-dkwave-nonprod --location westeurope
```

### Tags de gouvernance

```bash
az group update --name rg-dkwave-prod \
  --tags Company=DK-WAVE Environment=Prod Owner=IT CostCenter=IT-OPS

az group update --name rg-dkwave-nonprod \
  --tags Company=DK-WAVE Environment=NonProd Owner=IT CostCenter=IT-OPS

az group update --name rg-dkwave-shared \
  --tags Company=DK-WAVE Environment=Shared Owner=IT CostCenter=IT-OPS
```

### Utilisateurs Entra ID

```bash
# Compte administrateur
az ad user create \
  --display-name "Alice Admin" \
  --user-principal-name alice.admin@<TENANT_DOMAIN> \
  --password "<REDACTED>" \
  --force-change-password-next-sign-in true

# Opérateur
az ad user create \
  --display-name "Bob Ops" \
  --user-principal-name bob.ops@<TENANT_DOMAIN> \
  --password "<REDACTED>" \
  --force-change-password-next-sign-in true

# Compte de service — pas de changement de mot de passe imposé
az ad user create \
  --display-name "Service Backup" \
  --user-principal-name svc-backup@<TENANT_DOMAIN> \
  --password "<REDACTED>" \
  --force-change-password-next-sign-in false
```

### Groupes de sécurité

```bash
az ad group create --display-name "GRP-AZ-Admins" --mail-nickname "GRP-AZ-Admins"
az ad group create --display-name "GRP-AZ-Ops"    --mail-nickname "GRP-AZ-Ops"
az ad group create --display-name "GRP-AZ-Backup" --mail-nickname "GRP-AZ-Backup"
```

### Affectation des membres

```bash
# Alice → Admins
az ad group member add \
  --group GRP-AZ-Admins \
  --member-id $(az ad user show --id alice.admin@<TENANT_DOMAIN> --query id -o tsv)

# Bob → Ops
az ad group member add \
  --group GRP-AZ-Ops \
  --member-id $(az ad user show --id bob.ops@<TENANT_DOMAIN> --query id -o tsv)

# svc-backup → Backup
az ad group member add \
  --group GRP-AZ-Backup \
  --member-id $(az ad user show --id svc-backup@<TENANT_DOMAIN> --query id -o tsv)
```

### Attribution RBAC (Principe du moindre privilège)

```bash
# GRP-AZ-Admins → Owner sur rg-dkwave-shared
az role assignment create \
  --assignee-object-id $(az ad group show --group GRP-AZ-Admins --query id -o tsv) \
  --role "Owner" \
  --scope /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/rg-dkwave-shared

# GRP-AZ-Ops → Contributor sur prod et nonprod
az role assignment create \
  --assignee-object-id $(az ad group show --group GRP-AZ-Ops --query id -o tsv) \
  --role "Contributor" \
  --scope /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/rg-dkwave-prod

az role assignment create \
  --assignee-object-id $(az ad group show --group GRP-AZ-Ops --query id -o tsv) \
  --role "Contributor" \
  --scope /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/rg-dkwave-nonprod

# GRP-AZ-Backup → Backup Contributor sur l'abonnement
az role assignment create \
  --assignee-object-id $(az ad group show --group GRP-AZ-Backup --query id -o tsv) \
  --role "Backup Contributor" \
  --scope /subscriptions/<SUBSCRIPTION_ID>
```

### MFA & Accès conditionnel
Configurés via **Portail Azure** → Microsoft Entra ID → Security → Conditional Access

| Politique | Cible | Condition | Effet |
|---|---|---|---|
| `CA-MFA-Admins` | GRP-AZ-Admins | Toutes les apps | MFA obligatoire |
| `CA-Block-Risk` | Tous | Localisation hors pays de confiance | Accès bloqué |

---

## Tableau RBAC final

| Groupe | Rôle | Périmètre |
|---|---|---|
| `GRP-AZ-Admins` | Owner | `rg-dkwave-shared` |
| `GRP-AZ-Ops` | Contributor | `rg-dkwave-prod` + `rg-dkwave-nonprod` |
| `GRP-AZ-Backup` | Backup Contributor | Abonnement entier |

---

## Difficultés rencontrées

| Problème | Solution |
|---|---|
| RBAC nécessite l'Object ID, pas le nom | `az ad group show --query id` |
| Propagation RBAC lente (quelques minutes) | Patienter avant de tester |
| Accès conditionnel risque de bloquer l'admin | Tester en mode "Report-only" d'abord |

---

## Validation

| Critère | Statut |
|---|---|
| 3 groupes de ressources créés en West Europe | ✅ |
| Tags appliqués sur chaque RG | ✅ |
| MFA imposé pour GRP-AZ-Admins | ✅ |
| Bob ne peut pas supprimer `rg-dkwave-shared` | ✅ (RBAC correct) |
| `svc-backup` → Backup Contributor uniquement | ✅ |
