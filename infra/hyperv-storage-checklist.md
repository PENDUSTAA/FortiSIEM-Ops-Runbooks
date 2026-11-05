# Hyper-V / VM / storage review checklist

The guest cannot show these; check on the Hyper-V hosts (or SAN / storage array). PowerShell commands are suggestions to adapt, not run during this work.

## Host and VM
- Which physical host each ES VM runs on; spread master / hot-1 / hot-2 across different hosts.
- vCPU / RAM overcommit per host.
- Dynamic Memory must be OFF for ES VMs.
```powershell
Get-VM | Select Name,State,ProcessorCount,MemoryStartup,DynamicMemoryEnabled
Get-VMProcessor <vm> | Select Count,Reserve,Maximum,RelativeWeight
```

## Disks
- VHDX location and backing (SSD / HDD / SAN LUN), fixed vs dynamically expanding.
- Old checkpoints (snapshots) slow I/O badly: remove them.
```powershell
Get-VM | Get-VMHardDiskDrive | ForEach-Object { Get-VHD $_.Path | Select Path,VhdType,Size,FileSize }
Get-VM | Get-VMSnapshot
```
- Observed ~10 MB/s per shard recovery speed suggests slow or contended storage; check queue depth and latency on the datastore / LUN (array-side metrics if SAN).

## Guest (see `scripts/audit-node.sh`)
`nproc`, `free -m`, swap off, `df -hT`, `lsblk -o NAME,SIZE,TYPE,ROTA,MOUNTPOINT` (ROTA=1 means rotational), `iostat -x 1 3`, `vm.max_map_count` >= 262144, `ulimit -n`, JVM heap (`-Xms=-Xmx`, <= 50% RAM, < 32 GB), NTP sync, `dmesg` for OOM / I/O errors.

## Disk sizing / watermarks
Keep the smallest data node under ~70% used; unequal disk sizes make the smallest node hit 75% / 85% / 90% first.

## Backup
Add an ES snapshot repository + SLM policy, and/or replicas, before relying on the VHDX as the only copy.
