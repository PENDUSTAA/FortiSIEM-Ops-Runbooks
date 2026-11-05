# SAN / shared storage checklist (for Hyper-V hosts backing ES VMs)

Generic review items. Not run during the incident work; adapt to your array and fabric. Motivation: shard recovery ran at only ~10 MB/s per shard, which points to slow or contended storage.

## Array / LUN
- Which LUNs/volumes hold the ES VHDX files; tier (SSD / SAS / NL-SAS); RAID level; thin vs thick provisioning.
- Are ES VMs sharing LUNs/spindles with backup, VDI or other busy workloads?
- Array-side latency (read/write ms), IOPS, queue depth and throughput during indexing peaks and during shard recovery.
- Free capacity and thin-provisioning overcommit (a full pool stalls every VM).
- QoS / IOPS limits applied to the volume or VM.
- Array snapshots / replication schedules that may coincide with peak indexing.

## Fabric / paths
- iSCSI or FC; redundant paths (MPIO enabled and policy, e.g. round robin); both controllers active.
- Port/link speed, errors, CRC counters, flow control, jumbo frames end to end (iSCSI), dedicated storage VLAN/NICs.
```powershell
Get-MSDSMGlobalDefaultLoadBalancePolicy
mpclaim -s -d
Get-Disk | Select Number,FriendlyName,Size,OperationalStatus,HealthStatus
Get-PhysicalDisk | Select FriendlyName,MediaType,Size,HealthStatus
Get-Counter '\PhysicalDisk(*)\Avg. Disk sec/Read','\PhysicalDisk(*)\Avg. Disk sec/Write'
```
Target latency for ES hot data: low single-digit ms; sustained > 20 ms is a problem.

## Cluster Shared Volumes (if used)
- CSV health, redirected I/O state, owner node vs VM host, free space.
```powershell
Get-ClusterSharedVolume | Select Name,State
Get-ClusterSharedVolumeState
```

## Placement
- Spread ES data nodes across different LUNs/hosts so one volume or host failure does not take many nodes.
- Keep master-eligible nodes (master, hot-1, hot-2) on separate hosts/storage.
- Prefer fixed-size VHDX; avoid dynamic expansion and checkpoints on ES VMs.

## Protection
- ES has ~no replicas, so array snapshots are not a substitute for ES snapshots; add an ES snapshot repository (separate storage) and/or replicas.
