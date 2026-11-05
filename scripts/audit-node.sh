#!/usr/bin/env bash
# Script B: per VM (each ES node, Super, Workers), read-only. Output named by node IP.
O=/tmp/audit_$(hostname -I | awk '{print $1}').txt
{ echo "== cpu/mem"; nproc; free -m; swapon --show
  echo "== disks"; lsblk -o NAME,SIZE,TYPE,ROTA,MOUNTPOINT; df -hT | grep -v tmpfs
  echo "== io"; iostat -x 1 3 2>/dev/null | tail -20
  echo "== sysctl/limits"; sysctl vm.max_map_count vm.swappiness; ulimit -n
  echo "== es heap"; grep -hE "^-Xm[sx]" /etc/elasticsearch/jvm.options /etc/elasticsearch/jvm.options.d/* 2>/dev/null
  echo "== es yml"; grep -vE "^\s*(#|$)" /etc/elasticsearch/elasticsearch.yml 2>/dev/null
  echo "== time"; timedatectl | grep -E "synchronized|NTP|Time zone"
  echo "== recent oom/disk errors"; dmesg -T 2>/dev/null | grep -iE "oom|i/o error|blocked for more" | tail -10
} > $O 2>&1; echo $O
