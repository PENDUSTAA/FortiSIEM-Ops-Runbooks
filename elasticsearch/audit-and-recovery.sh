#!/usr/bin/env bash
# Read-only cluster checks. Set ES_URL to any node, e.g. http://192.0.2.10:9200
export ES_URL="${ES_URL:-http://192.0.2.10:9200}"
c() { curl -sS "$ES_URL$1"; }

echo "== health";        c "/_cluster/health?pretty"
echo "== nodes";         c "/_cat/nodes?v&h=name,ip,node.role,master,heap.percent,disk.used_percent"
echo "== disk";          c "/_cat/allocation?v"
echo "== active recov."; c "/_cat/recovery?active_only=true&v"
echo "== relocating";    c "/_cat/shards?v" | grep -E 'RELOCATING|INITIALIZING|UNASSIGNED'
echo "== write pools";   c "/_cat/thread_pool/write?v&h=node_name,active,queue,rejected"
echo "== settings";      c "/_cluster/settings?include_defaults=false&pretty"
echo "== ILM policies";  c "/_ilm/policy?pretty" | head -60
echo "== snapshots";     c "/_snapshot?pretty"

cat <<'NOTE'

# Rebalance control (run manually):
# pause:   curl -XPUT "$ES_URL/_cluster/settings" -H 'Content-Type: application/json' \
#            -d '{"transient":{"cluster.routing.rebalance.enable":"none"}}'
# restore: ...  {"transient":{"cluster.routing.rebalance.enable":"all"}}   # only after recoveries finish
NOTE
