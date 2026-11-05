# Diagrams

GitHub renders the Mermaid blocks below. Rendered SVGs and sources live in `diagrams/`.
Architecture is simplified: which Collector feeds which Worker, and the exact Super/Worker roles, depend on your deployment.

## 1. Platform architecture (simplified; IPs are placeholders)

```mermaid
flowchart LR
  subgraph Sources
    LA["Linux hosts<br/>FortiSIEM agent + rsyslog"]
    OT["Network / other devices<br/>syslog UDP 514"]
  end
  subgraph Collectors
    C1["Collector A"]
    C2["Collector B"]
    C3["Collector N"]
  end
  subgraph FortiSIEM
    SUP["Supervisor<br/>192.0.2.5"]
    W1["Worker 1<br/>192.0.2.6"]
    W2["Worker 2<br/>192.0.2.7"]
  end
  subgraph ES["Elasticsearch fsm-cluster (7.17)"]
    COORD["coord-1<br/>voting-only + ingest<br/>192.0.2.11"]
    M["master<br/>192.0.2.10"]
    H1["hot-1 32 vCPU"]
    H2["hot-2 16 vCPU"]
    H3["hot-3 8 vCPU"]
    H4["hot-4 16 vCPU"]
    H5["hot-5 8 vCPU"]
    H6["hot-6 8 vCPU"]
  end
  subgraph HV["Hyper-V hosts + SAN / shared storage"]
    ST[("VHDX on LUNs")]
  end
  LA -- "HTTPS 443 /linuxupload" --> C1
  OT -- "syslog" --> C2
  C1 --> W1
  C2 --> W2
  C3 --> SUP
  W1 -- "bulk" --> COORD
  W2 -- "bulk" --> COORD
  SUP -- "bulk / query" --> COORD
  COORD --> H1 & H2 & H3 & H4 & H5 & H6
  M -. "cluster state" .- COORD
  H1 & H2 & H3 & H4 & H5 & H6 -.-> ST
```

SVG: [`diagrams/01-architecture.svg`](../diagrams/01-architecture.svg)

## 2. Incident causal chain and fix

```mermaid
flowchart TD
  A["hot-3 / hot-5 / hot-6 on 1 vCPU"] --> B["Bulk load saturates CPU<br/>write pool = 1 thread"]
  B --> C["FsHealth stalls up to ~25 s"]
  C --> D["Master contact lost<br/>election storms"]
  D --> E["Nodes without master<br/>reject writes"]
  E --> F["Worker bulk 'took' ~60 s timeout"]
  F --> G["hwm(y) backpressure<br/>reject upload, status 550"]
  G --> H["Collector buffers grow (GB)"]
  F --> I["Events dropped<br/>drop counter rises"]
  subgraph Fix
    X1["Resize to 8 vCPU"]
    X2["Recovery throttle 100 -> 200 MB/s"]
    X3["Pause rebalance, move heavy shard<br/>hot-6 -> hot-1"]
    X4["Restore rebalance = all"]
    X5["Verify: green, queues 0,<br/>hwm(n), flat drop counters"]
    X1 --> X2 --> X3 --> X4 --> X5
  end
  A -. "remediated by" .-> X1
  X5 --> J["Buffers drain to ~0"]
```

SVG: [`diagrams/02-incident-chain.svg`](../diagrams/02-incident-chain.svg)

## 3. Runbook: relieve a saturated hot node

```mermaid
flowchart TD
  S["Write pool saturated on one node<br/>active == size, queue growing"] --> D["Find hottest shard<br/>scripts/hot-node-delta.sh"]
  D --> P["Pause rebalance<br/>rebalance.enable = none"]
  P --> M["POST _cluster/reroute move<br/>from hot-6 to hot-1"]
  M --> W{"_cat/recovery<br/>active_only shows it?"}
  W -- yes --> W2["Wait (100% may linger<br/>during translog handoff)"]
  W2 --> W
  W -- no --> R["Restore rebalance.enable = all"]
  R --> V["Verify health green,<br/>thread pools idle,<br/>Phoenix hwm(n) + flat drop"]
  V --> N{"Queue still full?"}
  N -- yes --> D
  N -- no --> DONE["Done"]
```

SVG: [`diagrams/03-shard-move-runbook.svg`](../diagrams/03-shard-move-runbook.svg)

## 4. Linux host log paths and where SELinux blocks

```mermaid
flowchart LR
  APP["Application<br/>writes files under /appdata"] --> IMF["rsyslog imfile<br/>tags facility local6"]
  APP2["App via syslog socket"] --> RS["rsyslog rules"]
  IMF --> RS
  RS -- "default rule *.info matches local6" --> MSG["/var/log/messages"]
  RS -- "explicit local6 -> messages rule" --> MSG
  RS -- "forward rule (omfwd @collector)" --> COL["Collector / FortiSIEM"]
  AG["FortiSIEM Linux agent<br/>templates: Syslog / Log File / FIM"] -- "HTTPS 443" --> COL
  AU["auditd + ausearch<br/>(called inside agent library)"] --> AG
  SEL["SELinux enforcing"] -. "denies list of /appdata<br/>(default_t) to syslogd_t" .-> IMF
  SEL -. "denies write to agent tmp (usr_t)<br/>fixed by relabel" .-> AG
  MSG -. "duplicates + setroubleshoot long lines" .- NOISE["Log noise / disk growth"]
```

SVG: [`diagrams/04-linux-log-paths.svg`](../diagrams/04-linux-log-paths.svg)

## 5. Why the sendmail warning appears

```mermaid
sequenceDiagram
  participant AG as FortiSIEM agent (libphLinuxAgentUtils.so)
  participant AS as ausearch
  participant AC as /etc/audit/auditd.conf
  participant SM as /usr/lib/sendmail
  participant LOG as /var/log/messages
  AG->>AS: run ausearch (stderr not redirected)
  AS->>AC: read config
  AC-->>AS: space_left_action = email
  AS->>SM: is it executable?
  SM-->>AS: missing
  AS-->>AG: warning on stderr
  AG->>LOG: "Email option is specified but /usr/lib/sendmail doesn't seem executable."
  Note over AC,LOG: Fix: email -> syslog, then kill -HUP auditd. FIM removal does not help.
```

SVG: [`diagrams/05-sendmail-warning.svg`](../diagrams/05-sendmail-warning.svg)

## 6. Troubleshooting: app logs intermittent after local6 change

```mermaid
flowchart TD
  S["App logs intermittent / missing after<br/>stopping local6 -> messages"] --> Q1{"Urgent?"}
  Q1 -- yes --> RB["Restore rsyslog backup<br/>rsyslogd -N1, restart"]
  Q1 -- no --> C1["scripts/linux-host-diag.sh"]
  C1 --> Q2{"rsyslogd -N1 OK?"}
  Q2 -- no --> F1["Fix config; orphaned '&' forward line?"]
  Q2 -- yes --> Q3{"AVC for in:imfile?"}
  Q3 -- yes --> F2["setsebool -P logging_syslogd_list_non_security_dirs on<br/>re-check AVC count = 0"]
  Q3 -- no --> Q4{"auditd/rsyslog restarted?<br/>NRestarts / timestamps"}
  Q4 -- yes --> F3["Find trigger: FIM/template change"]
  Q4 -- no --> Q5{"rate-limit / suppressed?"}
  Q5 -- yes --> F4["Raise rsyslog / journald limits"]
  Q5 -- no --> F5["logger -p local6.info test<br/>search FortiSIEM for it"]
```

SVG: [`diagrams/06-local6-troubleshooting.svg`](../diagrams/06-local6-troubleshooting.svg)
