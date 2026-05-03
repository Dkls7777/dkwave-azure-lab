# Phase 4 — Monitoring & Opérations
**DK WAVE TECHNOLOGY · Azure Administrator Hands-On Lab**

> **Statut** : ✅ Complétée

---

## Objectif

Donner une visibilité complète sur l'infrastructure. Sans monitoring, personne ne sait ce qui se passe en temps réel.

> *Si tu ne monitores pas, tu ne pilotes pas. Trois règles non négociables : (1) les utilisateurs ne doivent jamais découvrir un incident avant l'équipe IT ; (2) les problèmes doivent être détectés automatiquement ; (3) les logs doivent permettre une analyse rapide.*

---

## Ressources créées

| Ressource | Nom | Resource Group |
|---|---|---|
| Log Analytics Workspace | `law-dkwave-prod` | rg-dkwave-shared |
| Data Collection Rule | `dcr-dkwave-prod` | rg-dkwave-shared |
| Action Group | `ag-it-ops` | rg-dkwave-prod |
| Règle d'alerte CPU | `alert-high-cpu-app01` | rg-dkwave-prod |
| Règle d'alerte CPU | `alert-high-cpu-web02` | rg-dkwave-prod |

---

## Étapes réalisées

### 4.1 — Log Analytics Workspace

```bash
az monitor log-analytics workspace create \
  --resource-group rg-dkwave-shared \
  --workspace-name law-dkwave-prod \
  --location westeurope \
  --tags Environment=Shared Owner=IT Company=DK-WAVE CostCenter=IT-OPS
```

Rétention configurée à **30 jours** (équilibre visibilité / coût).

> Le workspace centralise tous les logs. Sans lui, chaque ressource conserve ses données de manière isolée — investigation longue et inefficace.

### 4.2 — Métriques Azure Monitor

Observation des métriques temps réel sur `vm-app01` :
- CPU stable à ~0.3 % en idle
- Pics jusqu'à 3.8 % lors des tests de charge
- Intervalle de collecte : PT5M (5 minutes)

> Les métriques = **ce qui est en train de casser**. Les logs = **pourquoi ça casse**.

### 4.3 — Agents Azure Monitor + Data Collection Rule

Installation des agents sur `vm-app01` (Ubuntu) et `vm-web02` (Windows) via `az rest` (workaround Azure Policy).

DCR configurée avec :
- Sources : `Syslog` (Linux) + `WindowsEventLogs` (Windows)
- Destination : `law-dkwave-prod`
- Associations : les deux VMs

> Un agent sans DCR reste muet. La DCR définit ce que l'agent collecte et où il l'envoie.

### 4.4 — Diagnostic Settings

Configuration sur NSG, Azure Firewall et Key Vault → envoi vers `law-dkwave-prod`.

Données reçues :
- **Azure Firewall** : 966 entrées `AzureDiagnostics` (très verbeux par nature)
- **NSG** : 109 entrées de trafic réseau

### 4.5 — Requêtes KQL (Kusto Query Language)

```kql
// Inventaire des types de logs disponibles
union * | summarize count() by Type | order by count_ desc

// Logs par type de ressource Azure
AzureDiagnostics | summarize count() by ResourceType | order by count_ desc

// Investigation CPU élevé sur vm-app01 (Phase 7)
Syslog
| where TimeGenerated > ago(30m)
| where Computer contains "vm-app01"
| project TimeGenerated, Computer, SeverityLevel, SyslogMessage
| take 10
```

> La maîtrise de KQL distingue un administrateur junior d'un administrateur senior.

### 4.6 & 4.7 — Action Group + Alertes CPU

```bash
# Action Group
az monitor action-group create \
  --resource-group rg-dkwave-prod \
  --name ag-it-ops \
  --short-name "IT-OPS" \
  --action email admin admin@dkwave.com

# Alerte CPU > 80% sur 5 minutes
az monitor metrics alert create \
  --resource-group rg-dkwave-prod \
  --name alert-high-cpu-app01 \
  --scopes <VM_ID> \
  --condition "avg Percentage CPU > 80" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --action ag-it-ops
```

| Paramètre | Valeur |
|---|---|
| Seuil | CPU moyen > 80 % |
| Fenêtre d'évaluation | 5 minutes |
| Fréquence | Toutes les 1 minute |
| Action | Email via `ag-it-ops` |

### 4.9 — Rétention des logs

30 jours configurés sur `law-dkwave-prod`. Pour des contextes réglementaires (RGPD, HDS, PCI-DSS) → 90 jours ou plus.

### 4.10 — Simulation d'incident (stress test)

Installation de l'outil `stress` sur `vm-app01` et simulation d'une montée en charge CPU pour tester l'ensemble du dispositif de monitoring de bout en bout.

---

## Difficultés rencontrées

| Problème | Impact | Solution |
|---|---|---|
| Azure Policy bloquait toutes les créations (tags obligatoires) | Bloquant | Toutes les ressources créées via `az rest` avec JSON complet incluant les tags |
| `az vm extension set` bloqué par la policy | Bloquant | Installation des agents via `az rest` direct |
| Données Perf/Heartbeat lentes à apparaître | Non bloquant | Latence normale Log Analytics (15-30 min) |

> **Workaround systématique** : dès qu'une commande CLI standard est bloquée par la policy de tags, utiliser `az rest` avec le body JSON complet.

---

## Validation

| Critère | Statut |
|---|---|
| Log Analytics Workspace créé | ✅ VALIDÉ |
| Agents installés sur vm-app01 et vm-web02 | ✅ VALIDÉ |
| DCR créée et associée aux VMs | ✅ VALIDÉ |
| Diagnostic Settings NSG + Firewall + KV | ✅ VALIDÉ |
| Données AzureDiagnostics reçues (966 entrées) | ✅ VALIDÉ |
| Alertes CPU actives (Sévérité 2) | ✅ VALIDÉ |
| Action Group email configuré | ✅ VALIDÉ |
| Requêtes KQL exécutées avec succès | ✅ VALIDÉ |
