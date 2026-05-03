# Rapport Technique Final
## DK WAVE TECHNOLOGY — Azure Administrator Hands-On Lab
### Phases 1 à 7 — Complétées

---

> **Auteur** : Kpedetin Lancelot Sam DOSSOU  
> **Formation** : Administrateur Systèmes & Réseaux Cloud  
> **École** : EFREI Paris · Ingénieur 1 · 2025-2026  
> **Période** : Avril 2026  
> **Statut** : 7/7 phases complétées ✅

---

## 1. Contexte & Mission

### 1.1 L'entreprise fictive

**DK WAVE TECHNOLOGY** est une startup éditrice de logiciels SaaS utilisée comme cadre de ce laboratoire pratique.

| Paramètre | Valeur |
|---|---|
| Effectif | 20 employés |
| Mode de travail | 100 % distanciel |
| Produit | Application SaaS web |
| Infrastructure on-premise | **Aucune** |
| Conformité | Hygiène de sécurité de base requise |
| Équipe IT | 1 seul administrateur |

### 1.2 Mission

Concevoir, déployer, sécuriser et opérer un environnement Azure de production **from scratch**, en respectant les standards enterprise :

- Architecture Hub-and-Spoke
- Principe du moindre privilège (Least Privilege)
- Modèle Zero Trust
- Defense in Depth
- Infrastructure as Code
- Monitoring proactif
- Résilience et continuité d'activité

---

## 2. Architecture finale déployée

```
Abonnement Azure — DK WAVE TECHNOLOGY
│
├── rg-dkwave-shared
│   ├── vnet-dkwave-prod (10.0.0.0/16)
│   │   ├── AzureFirewallSubnet   10.0.0.0/24
│   │   ├── GatewaySubnet         10.0.1.0/24
│   │   ├── subnet-web            10.0.10.0/24
│   │   ├── subnet-app            10.0.20.0/24
│   │   ├── subnet-db             10.0.30.0/24
│   │   ├── subnet-appgw          10.0.50.0/24
│   │   └── AzureBastionSubnet    10.0.40.0/26
│   ├── nsg-web / nsg-app / nsg-db
│   ├── azfw-dkwave (IP: 10.0.0.4 / pip: <FIREWALL_PUBLIC_IP>)
│   ├── bastion-dkwave
│   ├── rt-dkwave-fw (UDR → 0.0.0.0/0 via azfw-dkwave)
│   ├── law-dkwave-prod (Log Analytics, 30j rétention)
│   └── rsv-dkwave-prod (Recovery Services Vault)
│
├── rg-dkwave-prod
│   ├── vm-app01 (Ubuntu 24.04 LTS · Standard_D2ads_v6)
│   ├── vm-web02 (Windows Server 2025 · Standard_D2ads_v6)
│   ├── avset-dkwave-prod (2FD / 5UD)
│   ├── lb-dkwave-web (Standard SKU)
│   ├── appgw-dkwave (WAF_v2 · pip: <APPGW_PUBLIC_IP>)
│   └── kv-dkwave-secure (RBAC · Private Endpoint)
│
└── rg-dkwave-nonprod
    └── Storage account non-prod (Bicep IaC)
```

**Total : 39 ressources · 5 resource groups**

---

## 3. Synthèse par phase

### Phase 1 — Fondations ✅
- 3 groupes de ressources créés avec isolation stricte
- Tags de gouvernance standardisés (Company, Environment, Owner, CostCenter)
- 3 utilisateurs + 3 groupes de sécurité Entra ID
- RBAC via groupes uniquement (jamais directement sur les utilisateurs)
- MFA + Accès conditionnel activés (Zero Trust)

### Phase 2 — Infrastructure Cœur ✅
- VNet segmenté en 6 sous-réseaux (isolation par couche applicative)
- 3 NSG avec règles strictes et Deny-All implicite
- Azure Bastion (SSH/RDP sécurisé sans IP publique sur les VMs)
- 2 VMs déployées sans IP publique
- Availability Set (99,95 % SLA) + Load Balancer Standard

### Phase 3 — Sécurité & Gouvernance ✅
- Microsoft Defender for Cloud (Plan 2 Serveurs + Key Vault)
- Key Vault avec Private Endpoint — 0 secret en clair
- Azure Firewall + UDR (tout le trafic sortant inspecté)
- Application Gateway WAF_v2 en mode Prevention (OWASP CRS 2.1)
- Azure Policy (deny-public-ip + require-tags sur l'abonnement)
- Resource Locks CanNotDelete sur rg-shared et rg-prod

### Phase 4 — Monitoring & Opérations ✅
- Log Analytics Workspace centralisé (law-dkwave-prod)
- Agents Azure Monitor sur vm-app01 et vm-web02
- Data Collection Rule (Syslog Linux + WindowsEventLogs)
- Diagnostic Settings : NSG + Firewall + Key Vault
- Alertes CPU > 80 % avec Action Group email
- Requêtes KQL opérationnelles (investigation d'incidents)

### Phase 5 — Automatisation & Optimisation ✅
- Templates Bicep (IaC) déployés en Prod et NonProd
- Azure Update Manager — patching mensuel automatisé
- Audit tags : 8 ressources corrigées
- Budget mensuel 150 USD avec alertes 80 % / 100 %
- Right-sizing : CPU < 1 % → recommandation Standard_D1ads_v6

### Phase 6 — Résilience & DR ✅
- Recovery Services Vault (rsv-dkwave-prod)
- Backup Policy : Daily 23h · 14j / 4sem / 6 mois
- 2 VMs protégées (vm-app01 priorité haute, vm-web02 priorité moyenne)
- Backup initial manuel réalisé et validé
- **Test de restauration complet** : restore-disks validé dans rg-restore-test

### Phase 7 — Administration Quotidienne ✅
- Cycle de vie utilisateurs : JOINER + MOVER + LEAVER documentés
- Comptes de service : login interactif désactivé
- Incident Response : processus 5 étapes sur CPU > 90 %
- Change Management : resize vm-app01 avec processus complet
- Access Reviews : aucun privilege creep détecté
- Rotation de secret Key Vault (DbPassword)
- Inventaire complet 39 ressources

---

## 4. Points techniques remarquables

### 4.1 Azure Policy comme contrainte systématique

La policy `require-tags` (déployée en Phase 3) a bloqué **toutes** les commandes CLI standard dans les phases 4, 5, 6 et 7. Solution systématique adoptée : utilisation de `az rest` avec corps JSON complet incluant les 4 tags requis.

```bash
# Exemple de workaround systématique
az rest --method PUT \
  --uri "<ARM_RESOURCE_URI>?api-version=XXXX" \
  --body '{
    "location": "westeurope",
    "properties": { ... },
    "tags": {
      "Environment": "Prod",
      "Owner": "IT",
      "Company": "DK-WAVE",
      "CostCenter": "IT-OPS"
    }
  }'
```

### 4.2 Résolution cross-resource-group

L'Application Gateway dans `rg-dkwave-prod` ne trouvait pas son subnet dans `rg-dkwave-shared` via le nom simple. Solution : utilisation des ARM Resource IDs complets.

### 4.3 Key Vault Soft Delete

`kv-dkwave-prod` réservé 90 jours par Soft Delete → renommé `kv-dkwave-secure`. Cette fonctionnalité protège contre la perte accidentelle de secrets — un comportement Azure à connaître impérativement.

### 4.4 AzureBastionSubnet /26 obligatoire

Le lab indiquait /27 (32 adresses). Azure exige /26 minimum (64 adresses) — correction documentée et appliquée.

### 4.5 Azure asynchrone

Plusieurs opérations (attachement VMs à Update Manager, backup) ont généré des timeouts client alors que l'opération continuait en arrière-plan côté Azure. Un timeout client ≠ un échec serveur.

---

## 5. Bonnes pratiques démontrées

| Principe | Application concrète |
|---|---|
| **Zero Trust** | Vérification systématique à chaque couche — aucune confiance implicite |
| **Least Privilege** | RBAC via groupes · Key Vault Secrets User pour GRP-AZ-Ops |
| **Defense in Depth** | WAF → Firewall → NSG → VMs privées → KV isolé |
| **No Public IP on VMs** | Accès SSH/RDP exclusivement via Azure Bastion |
| **Secrets Management** | Zéro secret en clair · Key Vault + Private Endpoint |
| **IaC** | Templates Bicep reproductibles · CLI documentée phase par phase |
| **Backup Testing** | Restauration complète testée et validée (Phase 6) |
| **Cost Awareness** | Budget proactif · Right-sizing documenté |
| **Change Management** | Processus 6 étapes pour tout changement en production |
| **Separation of Duties** | rg-shared vs rg-prod vs rg-nonprod |

---

## 6. Compétences techniques démontrées

| Domaine | Compétences |
|---|---|
| **Azure CLI** | Déploiement d'infrastructure, `az rest`, gestion des ressources |
| **Réseau** | VNet, segmentation, NSG, routage UDR, Firewall L3/L4 |
| **Identité** | Entra ID, RBAC granulaire, MFA, Accès conditionnel, Joiner/Mover/Leaver |
| **Sécurité** | Defender for Cloud, Key Vault, WAF L7, Azure Policy, Resource Locks |
| **Monitoring** | Log Analytics, KQL, Azure Monitor, Alertes, Action Groups |
| **IaC** | Bicep (templates + paramètres multi-env), idempotence |
| **FinOps** | Cost Management, budgets, right-sizing |
| **DR** | Recovery Services Vault, backup policy, test de restauration |
| **Operations** | Incident Response, Change Management, Access Reviews, Secret Rotation |
| **Troubleshooting** | Adaptation aux contraintes réelles (Policy, quotas, versions, async) |

---

## 7. Conclusion

Ce laboratoire de 7 phases couvre l'intégralité du périmètre d'un administrateur Azure en entreprise : des fondations d'identité jusqu'aux opérations quotidiennes, en passant par la sécurité en profondeur, le monitoring, l'automatisation et la résilience.

Les contraintes rencontrées — Azure Policy bloquante, quotas de subscription, extensions CLI instables, comportement asynchrone d'Azure — reflètent fidèlement les défis d'un environnement Azure réel. La capacité à adapter la stratégie (portail → CLI → API REST) selon les contraintes et à documenter chaque écart est une compétence différenciante pour un administrateur cloud junior.

---

*Kpedetin Lancelot Sam DOSSOU — EFREI Paris — 2025-2026*
