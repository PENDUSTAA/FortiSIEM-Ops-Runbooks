# Incident: ES ingestion drops (summary)

## Environment
- FortiSIEM 7.4.1: 1 Supervisor, 2 Workers, Elasticsearch 7.17.x (6 hot data nodes, 1 master, 1 coordinating/voting-only), no replicas.
- ILM policy deletes at 90d; disk watermarks low 75% / high 85% / flood 90%.

## Symptoms
- Phoenix drop counters rising on Super and Workers.
- Bulk thread pools saturated; shard relocations in flight while rebalance was enabled.
- Roughly 1.2M events lost during a ~2.5h window; smaller losses around a node disk resize and on the Super afterwards.

## Resolution
1. Let in-flight shard recovery finish **before** restoring `cluster.routing.rebalance.enable=all`.
2. Confirm cluster green, write thread pools idle, `hwm(n)` on Super and both Workers.
3. Watch drop counters per node; record baseline and compare.

## Follow-ups from the audit
- No replicas / no confirmed snapshots: add snapshot repository and policy.
- ILM retention (90d) vs intended (120d): confirm and align.
- One hot node near 73% disk: add headroom before the 75% low watermark.
- Coordinating node is likely the only bulk endpoint (single point of failure): add a second endpoint in Workers.
- Review odd cluster settings (`unsafe-bootstrap`, very high `search.max_buckets`).
- Remove dead collectors from the collector list.

## Lesson
Do not re-enable rebalancing until relocations/recoveries are finished; check `_cat/recovery?active_only=true` first.
