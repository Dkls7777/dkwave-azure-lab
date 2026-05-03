# Phase 3 — Sécurité & Gouvernance
**DK WAVE TECHNOLOGY · Azure Administrator Hands-On Lab**

> **Statut** : ✅ Complétée · **Principe** : Zero Trust — ne jamais faire confiance, toujours vérifier

---

## Architecture de sécurité déployée

```
Internet
    │
    ▼
WAF — appgw-dkwave (mode Prevention · OWASP CRS 2.1)
    │
    ▼
Azure Firewall — azfw-dkwave (IP privée : 10.0.0.4)
    │
    ▼
NSG — nsg-web / nsg-app / nsg-db
    │
    ▼
VMs privées — aucune IP publique
    │
    ▼
Key Vault via Private Endpoint — kv-dkwave-secure
```

---

## Commandes CLI exécutées

### Microsoft Defender for Cloud
Activé via **Portail Azure** → Microsoft Defender for Cloud → Environment Settings
- Plan Defender pour les Serveurs (Plan 2) → vm-app01 + vm-web02
- Plan Defender pour Key Vault

### Azure Key Vault

> ⚠️ `kv-dkwave-prod` était réservé par Soft Delete (90 jours). Renommé `kv-dkwave-secure`.

```bash
# Création via az rest (Azure Policy bloque la commande standard)
az rest --method PUT \
  --uri "https://management.azure.com/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/rg-dkwave-prod/providers/Microsoft.KeyVault/vaults/kv-dkwave-secure?api-version=2023-07-01" \
  --body '{
    "location": "westeurope",
    "properties": {
      "sku": { "family": "A", "name": "standard" },
      "tenantId": "<TENANT_ID>",
      "enableRbacAuthorization": true,
      "enableSoftDelete": true
    },
    "tags": {
      "Environment": "Prod",
      "Owner": "IT",
      "Company": "DK-WAVE",
      "CostCenter": "IT-OPS"
    }
  }'

# Ajout d'un secret (valeur non exposée)
az keyvault secret set \
  --vault-name kv-dkwave-secure \
  --name DbPassword \
  --value "<REDACTED>"
```

### Least Privilege sur Key Vault

```bash
# Administrateur → accès complet
az role assignment create \
  --assignee <ADMIN_OBJECT_ID> \
  --role "Key Vault Administrator" \
  --scope /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/rg-dkwave-prod/providers/Microsoft.KeyVault/vaults/kv-dkwave-secure

# GRP-AZ-Ops → lecture seule sur les secrets
az role assignment create \
  --assignee $(az ad group show --group GRP-AZ-Ops --query id -o tsv) \
  --role "Key Vault Secrets User" \
  --scope /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/rg-dkwave-prod/providers/Microsoft.KeyVault/vaults/kv-dkwave-secure
```

### Azure Firewall

```bash
# IP publique
az network public-ip create \
  --resource-group rg-dkwave-shared \
  --name pip-azfw \
  --sku Standard \
  --allocation-method Static \
  --tags Environment=Shared Owner=IT Company=DK-WAVE CostCenter=IT-OPS

# Firewall
az network firewall create \
  --resource-group rg-dkwave-shared \
  --name azfw-dkwave \
  --location westeurope

# Configuration IP
az network firewall ip-config create \
  --resource-group rg-dkwave-shared \
  --firewall-name azfw-dkwave \
  --name fw-ipconfig \
  --public-ip-address pip-azfw \
  --vnet-name vnet-dkwave-prod
```

### User Defined Routes (UDR)

```bash
# Table de routage
az network route-table create \
  --resource-group rg-dkwave-shared \
  --name rt-dkwave-fw \
  --tags Environment=Shared Owner=IT Company=DK-WAVE CostCenter=IT-OPS

# Route par défaut → tout le trafic vers le Firewall
az network route-table route create \
  --resource-group rg-dkwave-shared \
  --route-table-name rt-dkwave-fw \
  --name DefaultRoute \
  --address-prefix 0.0.0.0/0 \
  --next-hop-type VirtualAppliance \
  --next-hop-ip-address 10.0.0.4

# Association aux sous-réseaux
az network vnet subnet update \
  --resource-group rg-dkwave-shared \
  --vnet-name vnet-dkwave-prod \
  --name subnet-web \
  --route-table rt-dkwave-fw

az network vnet subnet update \
  --resource-group rg-dkwave-shared \
  --vnet-name vnet-dkwave-prod \
  --name subnet-app \
  --route-table rt-dkwave-fw
```

### Application Gateway + WAF

```bash
# WAF Policy
az network application-gateway waf-policy create \
  --resource-group rg-dkwave-prod \
  --name waf-dkwave \
  --tags Environment=Prod Owner=IT Company=DK-WAVE CostCenter=IT-OPS

# Application Gateway WAF_v2
az network application-gateway create \
  --resource-group rg-dkwave-prod \
  --name appgw-dkwave \
  --location westeurope \
  --sku WAF_v2 \
  --capacity 1 \
  --vnet-name vnet-dkwave-prod \
  --subnet <SUBNET_APPGW_RESOURCE_ID> \
  --public-ip-address pip-appgw \
  --waf-policy waf-dkwave

# Activation mode Prevention
az network application-gateway waf-config set \
  --resource-group rg-dkwave-prod \
  --gateway-name appgw-dkwave \
  --enabled true \
  --firewall-mode Prevention \
  --rule-set-type OWASP
```

### Azure Policy

```bash
# Interdire les IPs publiques sur les NICs
az policy assignment create \
  --name "deny-public-ip" \
  --policy "Deny creation of Public IPs" \
  --scope /subscriptions/<SUBSCRIPTION_ID>

# Exiger les tags
az policy assignment create \
  --name "require-tags" \
  --policy "Require tag and its value" \
  --scope /subscriptions/<SUBSCRIPTION_ID>
```

### Resource Locks

```bash
az lock create \
  --name lock-shared-rg \
  --lock-type CanNotDelete \
  --resource-group rg-dkwave-shared

az lock create \
  --name lock-prod-rg \
  --lock-type CanNotDelete \
  --resource-group rg-dkwave-prod
```

---

## Difficultés rencontrées & solutions

| Problème | Solution |
|---|---|
| Key Vault RBAC : créateur sans accès au coffre | Attribution manuelle du rôle Key Vault Administrator (Zero Trust) |
| Portail Azure bloqué après désactivation accès public KV | Ajout de l'IP admin dans les règles firewall KV |
| `kv-dkwave-prod` réservé (Soft Delete 90 jours) | Renommé `kv-dkwave-secure` |
| `AzureFirewallSubnet` manquant | Créé avec le nom exact imposé par Azure |
| Extension `azure-firewall` CLI manquante | `az extension add --name azure-firewall` |
| App Gateway ne trouvait pas subnet cross-RG | Utilisation de l'ARM Resource ID complet |

---

## Validation

| Critère | Statut |
|---|---|
| Defender for Cloud actif sur Serveurs + KV | ✅ |
| Key Vault avec Private Endpoint | ✅ |
| Firewall inspecte le trafic sortant | ✅ |
| WAF en mode Prevention | ✅ |
| Policy bloque les IPs publiques | ✅ |
| Resource Locks actifs | ✅ |
| Tentative déploiement VM avec IP publique | ❌ Bloqué par Policy (attendu) |
