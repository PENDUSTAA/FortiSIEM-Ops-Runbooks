# Elasticsearch cheatsheet (FortiSIEM hot cluster)

```bash
export ES_URL="http://192.0.2.11:9200"     # coordinating node; set in EVERY new shell
```

## Layout (placeholders)
| Node | IP | Notes |
|---|---|---|
| master | 192.0.2.10 | role m |
| coord-1 | 192.0.2.11 | voting-only + ingest, likely main bulk endpoint |
| data-hot-1 | 192.0.2.21 | 32 vCPU |
| data-hot-2 | 192.0.2.22 | 16 vCPU |
| data-hot-3 | 192.0.2.23 | 8 vCPU (was 1) |
| data-hot-4 | 192.0.2.24 | 16 vCPU |
| data-hot-5 | 192.0.2.25 | 8 vCPU (was 1) |
| data-hot-6 | 192.0.2.26 | 8 vCPU (was 1) |

Cluster settings in force: `cluster_concurrent_rebalance: 4`, `indices.recovery.max_bytes_per_sec: 200mb`, `rebalance.enable: all`, disk watermarks 75/85/90%.

## Status
```bash
curl -sS "$ES_URL/_cluster/health?filter_path=status,relocating_shards,unassigned_shards"
curl -sS "$ES_URL/_cat/allocation?v&h=node,shards,disk.percent"
curl -sS "$ES_URL/_cat/recovery?active_only=true&v&h=index,source_node,target_node,bytes_percent,time"
curl -sS "$ES_URL/_cat/thread_pool/write?v&h=node_name,size,active,queue,rejected&s=node_name"
curl -sS "$ES_URL/_cat/nodeattrs?v"                       # box_type per node
curl -sS "$ES_URL/_cat/shards/<index>?v&h=index,shard,prirep,state,node"
curl -sS "$ES_URL/_cat/indices/fortisiem-event-*?h=index,pri,rep,store.size&s=store.size:desc"
curl -sS "$ES_URL/_cluster/allocation/explain?pretty"
```
Write pool size equals allocated vCPUs. `active == size` with a growing `queue` means the node is saturated.

## Move a shard off a saturated node
```bash
curl -sS -X POST "$ES_URL/_cluster/reroute?filter_path=acknowledged" -H 'Content-Type: application/json' \
  -d '{"commands":[{"move":{"index":"<index>","shard":0,"from_node":"data-hot-6","to_node":"data-hot-1"}}]}'
```
Pick the shard with the highest indexing rate (see `scripts/hot-node-delta.sh`). Recovery shows 100% for a while during translog handoff: wait for it to leave `_cat/recovery`.

## Rebalance control
```bash
# pause during manual moves
curl -sS -X PUT "$ES_URL/_cluster/settings" -H 'Content-Type: application/json' -d '{"persistent":{"cluster.routing.rebalance.enable":"none"}}'
# restore ONLY after active recoveries are gone
curl -sS -X PUT "$ES_URL/_cluster/settings" -H 'Content-Type: application/json' -d '{"persistent":{"cluster.routing.rebalance.enable":"all"}}'
```

## Recovery throttle
```bash
curl -sS -X PUT "$ES_URL/_cluster/settings" -H 'Content-Type: application/json' -d '{"persistent":{"indices.recovery.max_bytes_per_sec":"200mb"}}'
```
Observed ~10 MB/s per shard regardless of the cap, so the limit was disk/IO, not the throttle.

## ILM, templates, snapshots, aliases
```bash
curl -sS "$ES_URL/_ilm/policy/org_events_120d_v1?pretty"          # check delete.min_age
curl -sS "$ES_URL/<index>/_ilm/explain?pretty"
curl -sS "$ES_URL/_cat/templates/org*?v"
curl -sS "$ES_URL/_template/org-events-retention-override-v1?pretty"
curl -sS "$ES_URL/_snapshot?pretty"                                   # {} = no backup repo
curl -sS "$ES_URL/_cat/aliases/fortisiem-event-*?v"
curl -sS "$ES_URL/_cluster/settings?include_defaults=false&flat_settings=true&pretty"
```

## Node logs
`/var/log/elasticsearch/fsm-cluster.log` (UTC). Look for `FsHealth`, `master_left`, `elected`, `ClusterApplierService` stalls.
