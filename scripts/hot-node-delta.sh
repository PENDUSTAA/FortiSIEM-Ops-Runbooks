#!/usr/bin/env bash
# Which shards on a node are indexing fastest (30 s sample). Usage: NODE=data-hot-6 ./hot-node-delta.sh
export LC_ALL=C; NODE="${NODE:-data-hot-6}"; ES_URL="${ES_URL:-http://192.0.2.11:9200}"
q() { curl -sS "$ES_URL/_cat/shards?h=index,shard,node,iito" | awk -v n="$NODE" '$3==n{print $1"/"$2, $4}' | sort; }
q > /tmp/s1; sleep 30; q > /tmp/s2
join /tmp/s1 /tmp/s2 | awk '{d=$3-$2; if (d>0) printf "%s %d docs/30s\n",$1,d}' | sort -k2 -nr | head
