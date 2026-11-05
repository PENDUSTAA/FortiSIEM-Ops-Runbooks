# Platform audit (ES cluster, VMs, storage)

Method: read-only `scripts/audit-cluster.sh` (Script A) on any shell with `ES_URL`, `scripts/audit-node.sh` (Script B) per VM, plus Hyper-V host checks (`infra/hyperv-storage-checklist.md`).

## Healthy
- Cluster green, no unassigned shards, no rejected writes, CPU near idle.
- Master failover OK: `master`, hot-1, hot-2 electable; coord-1 is voting-only (an early "single master" concern was wrong).
- ILM `rollover_alias` mismatch is harmless because the policy has no rollover action.

## Findings (most important first)
1. **No replicas and no confirmed snapshots** (835 primaries / 838 active shards). Losing one VHDX or node loses data. Check `GET _snapshot`; `{}` means no backup.
2. **ILM policy deletes at 90 d, not the intended 120 d** (policy `org_events_120d_v1`). First automatic deletions ~2 weeks after the audit. Confirm intended retention before deletions start.
3. **Smallest hot node disk at ~73%** of 3.8 TB, ~74 GB below the 75% low watermark (no new shards), ~500 GB below 85% high (shards move away), ~700 GB below 90% flood (read-only, writes stop). Disk sizes are unequal (3.8 / 4.8 / 7.6 TB). Extend it or move big shards.
4. **Weakest nodes**: 8 GB heaps, one at ~67% heap; a master-eligible node at ~73% heap.
5. **Possibly a single bulk path**: coord-1 had ~1.6M bulk completions. Check FortiSIEM GUI (Admin > Settings > Database > Elasticsearch) for the Workers' ES endpoint list; add more endpoints.

## Smaller items
- `cluster.metadata.unsafe-bootstrap: true` is not a standard 7.17 setting; probably a leftover from an earlier recovery.
- `search.max_buckets` = 10,000,000 (default 65,536): one bad query can exhaust heap.
- ~25 empty 226-byte indices (clutter).
- 2-shard template (`order 101`) applies at rollover but not at daily index creation (FortiSIEM sets shard count itself).
- Mixed node roles (`him`, `sw`, `cs`) work via `box_type`, but would surprise anyone adding warm/cold ILM actions.
- No alerting on: write queue, rejected writes, `hwm=y`, drop counter increases (most useful fix to prevent a repeat).
- Dead collectors; Hot Node Age mismatch.

## Still open (needs outputs)
Script B per VM, snapshot check, ILM explain + template check, Hyper-V host review, Super drop timeline.
```bash
curl -sS "$ES_URL/_snapshot?pretty"
curl -sS "$ES_URL/<old-index>/_ilm/explain?pretty"
curl -sS "$ES_URL/_template/org-events-retention-override-v1?pretty"
```
