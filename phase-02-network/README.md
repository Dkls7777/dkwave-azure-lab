# Phase 2 — Infrastructure Cœur
**DK WAVE TECHNOLOGY · Azure Administrator Hands-On Lab**

> **Statut** : ✅ Complétée · **VMs déployées** : 2 · **IPs publiques sur VMs** : 0

---

## Objectif

Déployer une infrastructure réseau et de calcul complète, sécurisée et segmentée, prête pour la production.

> *La conception avant le déploiement est une règle fondamentale. Les erreurs réseau sont difficiles à corriger une fois les ressources en production.*

---

## Ressources créées

| Ressource | Nom | Resource Group |
|---|---|---|
| Réseau virtuel | `vnet-dkwave-prod` | rg-dkwave-shared |
| NSG | `nsg-web` / `nsg-app` / `nsg-db` | rg-dkwave-shared |
| Azure Bastion | `bastion-dkwave` | rg-dkwave-shared |
| IP publique Bastion | `pip-bastion-dkwave` | rg-dkwave-shared |
| VM Linux (App) | `vm-app01` | rg-dkwave-prod |
| VM Windows (Web) | `vm-web02` | rg-dkwave-prod |
| Availability Set | `avset-dkwave-prod` | rg-dkwave-prod |
| Load Balancer | `lb-dkwave-web` | rg-dkwave-prod |

---

## Plan d'adressage réseau

| Sous-réseau | Plage IP | Rôle |
|---|---|---|
| `AzureFirewallSubnet` | 10.0.0.0/24 | Azure Firewall (nom imposé par Azure) |
| `GatewaySubnet` | 10.0.1.0/24 | Passerelle VPN |
| `subnet-web` | 10.0.10.0/24 | Couche Web |
| `subnet-app` | 10.0.20.0/24 | Couche Application |
| `subnet-db` | 10.0.30.0/24 | Couche Base de données |
| `AzureBastionSubnet` | 10.0.40.0/26 | Accès admin sécurisé |

---

## Étapes réalisées

### 2.1 — Conception réseau (draw.io)
Diagramme réseau complet conçu avant tout déploiement : sous-réseaux, flux de trafic, services Azure associés.

### 2.2 — Réseau virtuel

```bash
az network vnet create \
  --resource-group rg-dkwave-shared \
  --name vnet-dkwave-prod \
  --location westeurope \
  --address-prefix 10.0.0.0/16
```

### 2.3 — Sous-réseaux

```bash
az network vnet subnet create \
  --resource-group rg-dkwave-shared \
  --vnet-name vnet-dkwave-prod \
  --name subnet-web \
  --address-prefix 10.0.10.0/24

# Note : /26 obligatoire — Azure Bastion exige minimum 64 adresses
az network vnet subnet create \
  --resource-group rg-dkwave-shared \
  --vnet-name vnet-dkwave-prod \
  --name AzureBastionSubnet \
  --address-prefix 10.0.40.0/26
```

### 2.4 — NSG

```bash
az network nsg create --resource-group rg-dkwave-shared --name nsg-web
az network nsg create --resource-group rg-dkwave-shared --name nsg-app
az network nsg create --resource-group rg-dkwave-shared --name nsg-db

# Règle HTTPS entrante sur nsg-web
az network nsg rule create \
  --resource-group rg-dkwave-shared \
  --nsg-name nsg-web \
  --name Allow-HTTPS \
  --priority 100 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --destination-port-ranges 443
```

> **Principe appliqué** : tout trafic non explicitement autorisé est bloqué par défaut (Deny-All implicite Azure).

### 2.5 — Azure Bastion
Déployé via le portail Azure dans `AzureBastionSubnet`. Permet SSH/RDP via HTTPS sans IP publique sur les VMs.

> *Toute VM avec une IP publique est un risque de sécurité immédiat. Bastion élimine cette surface d'attaque.*

### 2.6 — Machines virtuelles

| VM | OS | Taille | Sous-réseau | IP publique |
|---|---|---|---|---|
| `vm-app01` | Ubuntu 24.04 LTS | Standard_D2ads_v6 | subnet-app | **Aucune** |
| `vm-web02` | Windows Server 2025 | Standard_D2ads_v6 | subnet-web | **Aucune** |

### 2.7 — Availability Set

```bash
az vm availability-set create \
  --resource-group rg-dkwave-prod \
  --name avset-dkwave-prod \
  --platform-fault-domain-count 2 \
  --platform-update-domain-count 5
```

> Garantit que les VMs ne tombent pas simultanément → SLA 99,95 %.

### 2.8 — Load Balancer

```bash
az network lb create \
  --resource-group rg-dkwave-prod \
  --name lb-dkwave-web \
  --sku Standard \
  --vnet-name vnet-dkwave-prod \
  --subnet subnet-web
```

---

## Difficultés rencontrées & solutions

| Problème | Cause | Solution |
|---|---|---|
| `AzureBastionSubnet /27` refusé | Azure exige /26 minimum | Recréation en /26 (10.0.40.0/26) |
| `Extra data line 1 col 4` en CLI | Bug parsing JSON Cloud Shell | Déploiement VMs basculé sur portail Azure |
| `Standard_B2s` indisponible | SKU non disponible en West Europe | Remplacé par `Standard_D2ads_v6` |
| Guillemets typographiques | Copie depuis PDF du lab | Saisie manuelle des commandes |

---

## Écarts documentés

| Paramètre | Lab original | Réalisé | Raison |
|---|---|---|---|
| Taille VM | Standard_B2s | **Standard_D2ads_v6** | SKU indisponible en West Europe |
| Image Linux | Ubuntu 22.04 | **Ubuntu 24.04 LTS** | Version LTS plus récente |
| Image Windows | Windows Server 2022 | **Windows Server 2025** | Version plus récente |
| AzureBastionSubnet | /27 | **/26** | Requis par Azure |
| Création VMs | Azure CLI | **Portail Azure** | Bug JSON Cloud Shell |

---

## Validation

| Critère | Statut |
|---|---|
| VNet et sous-réseaux créés | ✅ VALIDÉ |
| NSG appliqués sur chaque sous-réseau | ✅ VALIDÉ |
| Aucune VM avec IP publique | ✅ CONFIRMÉ |
| Azure Bastion opérationnel | ✅ VALIDÉ |
| Connexion VM via Bastion | ✅ TESTÉ |
| Tentative RDP direct depuis Internet | ❌ BLOQUÉ (attendu) |

---

## Règle fondamentale

> **Aucune machine virtuelle n'est exposée directement à Internet.**  
> Tout accès administrateur passe exclusivement par **Azure Bastion**.  
> Cette règle est non négociable en environnement de production.
