# Incident: Elasticsearch stalls and FortiSIEM event drops

## Environment
- FortiSIEM 7.4.1: 1 Supervisor, 2 Workers, multiple Collectors.
- Elasticsearch 7.17.3, cluster `fsm-cluster`, 8 Hyper-V guests: `master` (role m), `coord-1` (voting-only + ingest), `data-hot-1..6`.
- vCPU: hot-1 32, hot-2 16, hot-4 16, hot-3/5/6 originally 1, later 8.
- Essentially no replicas (~0.4%): any data-node outage fails writes for the primaries it holds.
- Placement by custom attribute `box_type: hot` on all six data nodes plus `total_shards_per_node: 2`; ES balances by shard **count**, not CPU, so heavy writers can pile onto weak nodes.
- FortiSIEM owns index naming (`fortisiem-event-<date>-<orgId>-00000N`), per-day aliases and size-based rollovers.
- VMs share one hostname, so identify nodes by IP or `[data-hot-N]` in ES logs. ES logs are UTC.

## Root cause
hot-5 and hot-6 (and hot-3) ran on 1 vCPU. Under bulk load they stalled (FsHealth stalls up to ~25 s), lost master contact and caused election storms. Nodes without a master reject writes, so Workers saw bulk `took` near 60 s (timeout), set `hwm(y)` backpressure, rejected collector uploads (status 550) and dropped events.

## Loss
- ~1.2M events during ~2.5 h on day 1.
- ~55k around the hot-3 resize (older-day indices still receiving writes lived there).
- ~46k on the Supervisor between two checks on day 2 (not dated; timeline script below).

## Fix applied
1. Resized hot-5, hot-6, hot-3 to 8 vCPU.
2. Raised `indices.recovery.max_bytes_per_sec` 100mb -> 200mb (observed speed was only ~10 MB/s per shard, so disk-bound).
3. Paused rebalance, moved a heavy single-shard index off hot-6 (hot-6 showed 8 active / 13 queued write threads):
   `POST _cluster/reroute` `move` from data-hot-6 to data-hot-1.
4. Restored `cluster.routing.rebalance.enable=all` after recoveries finished.
5. Verified: cluster green, 0 relocating/unassigned, write pools idle, `hwm(n)` and flat drop counters on Super and both Workers; collector buffers drained.

## Mistakes worth remembering
- Restoring rebalance to `all` **before** the in-flight recovery finished. Harmless here, but check `_cat/recovery?active_only=true` first.
- Concluding "only hot-1/hot-2 are hot nodes" from role letters; `_cat/nodeattrs` showed `box_type=hot` on all six.
- Assuming a hot-3 resize costs no ingest (it did).
- Planning a manual rollover; FortiSIEM manages its own rollover and aliases.
- Forgetting `export ES_URL=...` in a new shell (`curl: (3) URL malformed`).

## Verification checklist (after any ES disturbance)
```bash
curl -sS "$ES_URL/_cluster/health?filter_path=status,relocating_shards,unassigned_shards"
curl -sS "$ES_URL/_cat/recovery?active_only=true&v"
curl -sS "$ES_URL/_cat/thread_pool/write?v&h=node_name,size,active,queue,rejected&s=node_name"
# on Super + each Worker:
grep "stats:" /opt/phoenix/log/phoenix.log | tail -2 | grep -o "drop/bp=.*hwm([yn]"
```
Healthy: green, no recoveries, queues 0, `hwm(n)`, drop counter unchanged between reads.

## Cleanup items
Dead collectors still listed (silent for months); one collector CPU Critical; GUI "Hot Node Age" shows 99 days (mismatch).
