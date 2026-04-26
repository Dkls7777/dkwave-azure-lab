#  DK WAVE TECHNOLOGY – Azure Administrator Hands-On Lab

<p align="center">
  <img src="https://img.shields.io/badge/Azure-Cloud-0078D4?style=for-the-badge&logo=microsoftazure&logoColor=white"/>
  <img src="https://img.shields.io/badge/Status-In%20Progress-yellow?style=for-the-badge"/>
  <img src="https://img.shields.io/badge/Level-Junior%20to%20Mid-green?style=for-the-badge"/>
</p>

---

## 🇫🇷 Français

###  Contexte

Ce dépôt contient la documentation complète et les scripts d'un laboratoire pratique Azure réalisé dans le cadre d'une formation **Administrateur Systèmes & Réseaux Cloud**.

L'entreprise fictive **DK WAVE TECHNOLOGY** est une startup éditrice de logiciels SaaS avec 20 employés, une main-d'œuvre à distance et aucun centre de données sur site. L'objectif est de concevoir, déployer, sécuriser et opérer un environnement Azure de type production **from scratch**.

###  Objectifs pédagogiques

- Concevoir une architecture Azure entreprise (Hub-and-Spoke)
- Déployer une infrastructure complète via Azure CLI et le portail Azure
- Sécuriser les identités (Entra ID, RBAC, MFA, Accès conditionnel)
- Mettre en place le monitoring et les alertes (Azure Monitor, Log Analytics)
- Automatiser les déploiements (Bicep, Azure CLI)
- Implémenter une stratégie de sauvegarde et de reprise après sinistre
- Opérer l'environnement au quotidien comme un vrai administrateur Azure

###  Technologies utilisées

| Domaine | Services Azure |
|---|---|
| Identité & Accès | Microsoft Entra ID, RBAC, MFA, Accès conditionnel |
| Réseau | VNet, NSG, Azure Firewall, Bastion, Load Balancer, Application Gateway |
| Calcul | Virtual Machines (Linux/Windows), Availability Sets, VM Scale Sets |
| Stockage & Backup | Azure Storage, Recovery Services Vault, Azure Backup |
| Sécurité | Defender for Cloud, Key Vault, WAF, Azure Policy, Resource Locks |
| Monitoring | Azure Monitor, Log Analytics, KQL, Alertes, Dashboards |
| Automatisation | Azure CLI, Bicep, Update Manager, Cost Management |
| Reprise après sinistre | Azure Site Recovery, Test Failover |

###  Structure du projet

```
dkwave-azure-lab/
├── README.md                        # Ce fichier
├── phase-01-foundations/            # Groupes de ressources, Entra ID, RBAC, MFA
├── phase-02-network/                # VNet, sous-réseaux, NSG, Bastion, VMs
├── phase-03-security/               # Defender, Key Vault, Firewall, WAF, Policy
├── phase-04-monitoring/             # Log Analytics, Azure Monitor, Alertes, KQL
├── phase-05-automation/             # Bicep, Update Manager, Cost Management
├── phase-06-resilience/             # Backup, Recovery Vault, ASR, Failover
├── phase-07-operations/             # Administration quotidienne, Incident Response
└── docs/                            # Documentation architecture et procédures
```

###  Roadmap

| Phase | Titre | Statut |
|---|---|---|
| Phase 1 | Mise en place des fondations |  Complétée |
| Phase 2 | Infrastructure cœur |  Complétée |
| Phase 3 | Sécurité & gouvernance |  Complétée |
| Phase 4 | Monitoring & opérations |  En cours |
| Phase 5 | Automatisation & optimisation |  À venir |
| Phase 6 | Résilience & reprise après sinistre |  À venir |
| Phase 7 | Administration quotidienne |  À venir |

###  Sécurité

> Aucun secret, mot de passe, clé d'API ou ID d'abonnement Azure n'est commis dans ce dépôt.
> Tous les secrets sont gérés via **Azure Key Vault**.

---

## 🇬🇧 English

###  Context

This repository contains the full documentation and scripts of a hands-on Azure lab completed as part of a **Cloud Systems & Network Administrator** training program.

The fictional company **DK WAVE TECHNOLOGY** is a SaaS software startup with 20 employees, a remote workforce, and no on-premises data center. The goal is to design, deploy, secure, and operate a production-grade Azure environment **from scratch**.

###  Learning Objectives

- Design an enterprise Azure architecture (Hub-and-Spoke)
- Deploy a complete infrastructure using Azure CLI and the Azure Portal
- Secure identities (Entra ID, RBAC, MFA, Conditional Access)
- Set up monitoring and alerting (Azure Monitor, Log Analytics)
- Automate deployments (Bicep, Azure CLI)
- Implement a backup and disaster recovery strategy
- Operate the environment daily like a real Azure administrator

###  Technologies Used

| Domain | Azure Services |
|---|---|
| Identity & Access | Microsoft Entra ID, RBAC, MFA, Conditional Access |
| Networking | VNet, NSG, Azure Firewall, Bastion, Load Balancer, Application Gateway |
| Compute | Virtual Machines (Linux/Windows), Availability Sets, VM Scale Sets |
| Storage & Backup | Azure Storage, Recovery Services Vault, Azure Backup |
| Security | Defender for Cloud, Key Vault, WAF, Azure Policy, Resource Locks |
| Monitoring | Azure Monitor, Log Analytics, KQL, Alerts, Dashboards |
| Automation | Azure CLI, Bicep, Update Manager, Cost Management |
| Disaster Recovery | Azure Site Recovery, Test Failover |

### Project Structure

```
dkwave-azure-lab/
├── README.md                        # This file
├── phase-01-foundations/            # Resource groups, Entra ID, RBAC, MFA
├── phase-02-network/                # VNet, subnets, NSG, Bastion, VMs
├── phase-03-security/               # Defender, Key Vault, Firewall, WAF, Policy
├── phase-04-monitoring/             # Log Analytics, Azure Monitor, Alerts, KQL
├── phase-05-automation/             # Bicep, Update Manager, Cost Management
├── phase-06-resilience/             # Backup, Recovery Vault, ASR, Failover
├── phase-07-operations/             # Daily administration, Incident Response
└── docs/                            # Architecture documentation and procedures
```

###  Roadmap

| Phase | Title | Status |
|---|---|---|
| Phase 1 | Foundations |  Completed |
| Phase 2 | Core Infrastructure |  Completed |
| Phase 3 | Security & Governance | Completed |
| Phase 4 | Monitoring & Operations |  In Progress |
| Phase 5 | Automation & Optimization |  Upcoming |
| Phase 6 | Resilience & Disaster Recovery |  Upcoming |
| Phase 7 | Daily Administration |  Upcoming |

###  Security Notice

> No secrets, passwords, API keys, or Azure subscription IDs are committed to this repository.
> All secrets are managed through **Azure Key Vault**.

---

<p align="center">
  Made with  by <strong>Kpedetin Lancelot Sam DOSSOU</strong> · EFREI Paris · 2025-2026
</p>
