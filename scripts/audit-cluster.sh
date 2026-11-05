#!/usr/bin/env bash
# Script A: cluster-level, read-only. Output: /tmp/audit_cluster.txt
export ES_URL="${ES_URL:-http://192.0.2.11:9200}"; O=/tmp/audit_cluster.txt; : > $O
for p in "_cat/nodes?v&h=name,ip,node.role,master,heap.percent,ram.percent,cpu,load_5m,disk.used_percent" \
         "_cat/master?v" "_cluster/health?pretty" \
         "_cluster/settings?include_defaults=false&flat_settings=true&pretty" \
         "_cat/allocation?v" "_cat/templates/org*?v" \
         "_ilm/policy/org_events_120d_v1?pretty" \
         "_cat/indices/fortisiem-event-*?h=index,pri,rep,store.size&s=store.size:desc" \
         "_nodes/stats/fs,os,jvm,thread_pool?filter_path=nodes.*.name,nodes.*.os.cpu.percent,nodes.*.jvm.mem.heap_max_in_bytes,nodes.*.fs.total,nodes.*.thread_pool.write&pretty" \
         "_cluster/allocation/explain?pretty" "_snapshot?pretty"; do
  echo "=== $p" >> $O; curl -sS "$ES_URL/$p" >> $O 2>&1; echo >> $O
done; wc -l $O
