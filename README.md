<p align="center">
  <img src="https://img.shields.io/badge/Microsoft_Azure-0078D4?style=for-the-badge&logo=microsoftazure&logoColor=white"/>
  <img src="https://img.shields.io/badge/Status-Completed-brightgreen?style=for-the-badge"/>
  <img src="https://img.shields.io/badge/Phases-7%2F7-blue?style=for-the-badge"/>
  
</p>

<h1 align="center">WAVE CONSULTING</h1>
<h3 align="center">Azure Administrator Hands-On Lab — Full Infrastructure Project</h3>

<p align="center">
  <em>Conception, déploiement, sécurisation et opération d'un environnement Azure de production from scratch</em>
</p>

---

##  Objectif

Ce dépôt documente un laboratoire pratique complet d'administration Azure, réalisé dans le cadre de la formation **Administrateur Systèmes & Réseaux Cloud** .

L'entreprise  ** WAVE CONSULTING** est une startup SaaS de 20 employés, 100 % distancielle, sans datacenter on-premise. La mission : construire une infrastructure Azure complète, sécurisée et opérationnelle **from scratch**, en respectant les standards enterprise.

---

## 🗺️ Roadmap — 7 Phases

| # | Phase | Contenu | Statut |
|---|---|---|---|
| 1 | [**Fondations**](./phase-01-foundations/) | Groupes de ressources · Entra ID · RBAC · MFA · Tags | ✅ Complétée |
| 2 | [**Infrastructure Cœur**](./phase-02-network/) | VNet · NSG · Bastion · VMs · Load Balancer · Availability Set | ✅ Complétée |
| 3 | [**Sécurité & Gouvernance**](./phase-03-security/) | Defender · Key Vault · Firewall · WAF · Policy · Locks | ✅ Complétée |
| 4 | [**Monitoring & Opérations**](./phase-04-monitoring/) | Log Analytics · Azure Monitor · KQL · Alertes · DCR | ✅ Complétée |
| 5 | [**Automatisation & Optimisation**](./phase-05-automation/) | Bicep IaC · Update Manager · Cost Management · Right-sizing | ✅ Complétée |
| 6 | [**Résilience & DR**](./phase-06-resilience/) | Recovery Vault · Backup Policy · Test de restauration | ✅ Complétée |
| 7 | [**Administration Quotidienne**](./phase-07-operations/) | Joiner/Mover/Leaver · Incident Response · Change Management | ✅ Complétée |

---

## 🏗️ Architecture déployée

```
Abonnement Azure — Wave consulting
│
├── rg-dkwave-shared          ← Services partagés
│   ├── vnet-dkwave-prod      ← VNet central 10.0.0.0/16
│   │   ├── AzureFirewallSubnet     10.0.0.0/24
│   │   ├── GatewaySubnet           10.0.1.0/24
│   │   ├── subnet-web              10.0.10.0/24
│   │   ├── subnet-app              10.0.20.0/24
│   │   ├── subnet-db               10.0.30.0/24
│   │   ├── subnet-appgw            10.0.50.0/24
│   │   └── AzureBastionSubnet      10.0.40.0/26
│   ├── nsg-web / nsg-app / nsg-db
│   ├── azfw-dkwave           ← Azure Firewall
│   ├── bastion-dkwave        ← Accès SSH/RDP sécurisé
│   ├── rt-dkwave-fw          ← UDR → tout le trafic via Firewall
│   ├── law-dkwave-prod       ← Log Analytics Workspace
│   └── rsv-dkwave-prod       ← Recovery Services Vault
│
├── rg-dkwave-prod            ← Production
│   ├── vm-app01              ← Ubuntu 24.04 LTS
│   ├── vm-web02              ← Windows Server 2025
│   ├── avset-dkwave-prod     ← Availability Set
│   ├── lb-dkwave-web         ← Load Balancer Standard
│   ├── appgw-dkwave          ← Application Gateway WAF_v2
│   └── kv-dkwave-secure      ← Key Vault (Private Endpoint)
│
└── rg-dkwave-nonprod         ← Dev/Test
```

### Flux de sécurité (Defense in Depth)

```
Internet
    │
    ▼
WAF — appgw-dkwave (Prevention · OWASP CRS 2.1)
    │
    ▼
Azure Firewall — azfw-dkwave (trafic sortant inspecté via UDR)
    │
    ▼
NSG — nsg-web / nsg-app / nsg-db
    │
    ▼
VMs privées — aucune IP publique (accès admin via Bastion uniquement)
    │
    ▼
Key Vault via Private Endpoint
```

---

## 🛠️ Outils & Technologies

| Domaine | Services Azure |
|---|---|
| **Identité & Accès** | Microsoft Entra ID · RBAC · MFA · Accès Conditionnel |
| **Réseau** | VNet · NSG · Azure Firewall · UDR · Bastion · App Gateway |
| **Calcul** | Virtual Machines · Availability Set · Load Balancer |
| **Sécurité** | Defender for Cloud · Key Vault · WAF · Azure Policy · Resource Locks |
| **Monitoring** | Azure Monitor · Log Analytics · KQL · Alertes · Action Groups |
| **Automatisation** | Azure CLI · Bicep (IaC) · Azure REST API · Update Manager |
| **FinOps** | Cost Management · Budgets · Right-sizing |
| **DR** | Recovery Services Vault · Backup Policy · Test de restauration |

---

## 📁 Structure du dépôt

```
dkwave-azure-lab/
├── README.md                    ← Vue d'ensemble du projet
├── .gitignore
├── docs/
│   └── RAPPORT-FINAL.md         ← Rapport technique complet
├── iac/
│   ├── main.bicep               ← Template Bicep principal
│   ├── vm.bicep                 ← Template VM
│   ├── prod.parameters.json     ← Paramètres Production
│   └── nonprod.parameters.json  ← Paramètres NonProd
├── diagrams/
│   └── README.md                ← Schémas d'architecture
├── screenshots/
│   └── README.md                ← Captures de validation
├── phase-01-foundations/        ← Identités, RBAC, MFA, Tags
├── phase-02-network/            ← VNet, NSG, Bastion, VMs, LB
├── phase-03-security/           ← Defender, KV, Firewall, WAF, Policy
├── phase-04-monitoring/         ← Log Analytics, Monitor, KQL, Alertes
├── phase-05-automation/         ← Bicep, Update Manager, Cost Mgmt
├── phase-06-resilience/         ← RSV, Backup, Restauration
└── phase-07-operations/         ← Admin quotidienne, IR, Change Mgmt
```

---

## 💡 Points techniques remarquables

- **Azure Policy bloquante** : la policy de tags obligatoires bloquait toutes les commandes CLI standard → workaround systématique via `az rest` avec JSON complet
- **Key Vault Soft Delete** : `kv-dkwave-prod` réservé 90 jours → renommé `kv-dkwave-secure`
- **AzureBastionSubnet** : le lab indiquait /27 → Azure exige /26 minimum (corrigé)
- **Cross-resource-group** : utilisation des ARM Resource IDs complets pour résoudre les références inter-RG
- **Azure asynchrone** : un timeout client ≠ un échec serveur (validé via portail)

---

## 🔒 Bonnes pratiques appliquées

| Principe | Application |
|---|---|
| **Zero Trust** | Vérification systématique à chaque couche |
| **Least Privilege** | RBAC via groupes · jamais directement sur les utilisateurs |
| **No Public IP on VMs** | Accès SSH/RDP exclusivement via Azure Bastion |
| **Secrets Management** | Zéro secret en clair · tout dans Key Vault + Private Endpoint |
| **IaC** | Templates Bicep reproductibles |
| **Backup Testing** | Restauration complète testée et validée |

---

## ⚠️ Sécurité

> Aucun secret, mot de passe, clé d'API, ID d'abonnement ou IP publique réelle n'est commis dans ce dépôt.  
> Toutes les valeurs sensibles sont remplacées par `<REDACTED>` ou des placeholders.  
> Les secrets sont gérés exclusivement via **Azure Key Vault**.

---

<p align="center">
  Réalisé par <strong>Kpedetin Lancelot Sam DOSSOU</strong><br/>
   · Ingénieur 1 · 2025-2026
</p>
