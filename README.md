# FortiSIEM Ops Runbooks

Sanitized notes, commands and drafts from FortiSIEM 7.4.x + Elasticsearch 7.17 operations work
(incident response, platform audit, Linux agent / rsyslog / SELinux troubleshooting).

All IPs, hostnames, collector names, org IDs and customer paths are placeholders
(`192.0.2.x` per RFC 5737, `<...>`, `prd-web-01`, `/appdata`). Replace before use. Review every command before running in production.

| Path | Content |
|---|---|
| `docs/incident-es-ingestion.md` | Full RCA and timeline of the ES / ingestion incident, losses, fixes, mistakes to avoid |
| `docs/platform-audit-findings.md` | Audit of ES cluster, VM and storage; prioritized findings and open items |
| `elasticsearch/cheatsheet.md` | Cluster layout, every ES command we used (health, recovery, reroute, throttle, ILM, templates, snapshots) |
| `elasticsearch/audit-and-recovery.sh` | Quick read-only status script |
| `fortisiem/phoenix-drop-monitoring.md` | Reading Phoenix stats: drop counters, `hwm`, rejections, collector buffers |
| `infra/hyperv-storage-checklist.md` | Hyper-V / VM / disk storage review checklist |
| `infra/san-storage-checklist.md` | SAN / shared storage (LUN, MPIO, CSV, latency) checklist |
| `scripts/` | Cluster audit (A), per-node audit (B), Phoenix check, hot-node shard delta, Linux host diagnostics |
| `linux-agent/` | auditd sendmail warning, SELinux (agent tmp + rsyslog imfile), rsyslog local6, FIM/template notes, logrotate |
| `templates/` | Vendor support email, customer message |
