# Reading FortiSIEM Phoenix stats (Super / Workers)

Log: `/opt/phoenix/log/phoenix.log`. Each node keeps its own independent `drop` counter.

## Quick check (run on Super, Worker1, Worker-2)
```bash
hostname; grep "stats:" /opt/phoenix/log/phoenix.log | tail -2 | grep -o "drop/bp=.*hwm([yn]"
tail -n 500 /opt/phoenix/log/phoenix.log | grep -ic "congested\|reject upload"
```
- `drop/bp=a(b)/c(d)/e(f)/g(h)/0`: the 4th group `g(h)` is the drop counter used as baseline (e.g. `1325(4242863)`).
- `hwm(y)` = backpressure on; `hwm(n)` = clear. Healthy: `hwm(n)`, last two lines identical (counter not moving).
- Record a baseline per node and compare later: delta = events dropped since.
- Rejection lines `Server is not running or congested, reject upload request` and collector upload failures `status 550` mean the Worker is refusing uploads.
- `took` near 60,000 ms = bulk timeout; that is where drops occur.

## Timeline of the drop counter (dates a loss)
```bash
grep "stats:" /opt/phoenix/log/phoenix.log | awk 'NR%5==0' \
 | sed -E 's/^(2026-[^.]*)\..*took\/event\/fail=([0-9]+)\/[0-9]+\/([0-9]+)\/.*drop\/bp=[^/]*\/[^/]*\/[^/]*\/([^/]*)\/.*hwm\(([yn]).*/\1 eps=\2 took=\3 drop=\4 hwm=\5/' \
 | awk '{if($4!=p){print;p=$4}}' | tail -20
```

## Collector health
- GUI Collector Health: buffer size (MB/GB), Last File Received, Last Event Time, CPU.
- A growing buffer with stale Last File Received = collector cannot upload (Worker congested). Do not restart a collector holding a large buffer (buffered events could be lost); look at its own logs.
- Expect buffers to drain to ~0 once `hwm(n)`.

## Alerts worth creating (none existed)
Write-queue > 0 for minutes, any rejected writes, `hwm=y`, drop counter increase, cluster status != green, node disk > 70%.
